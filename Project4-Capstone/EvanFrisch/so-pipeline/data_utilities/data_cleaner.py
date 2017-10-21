from pyspark.sql import SQLContext, DataFrameReader
from pyspark.sql.functions import datediff, udf, mean, min, max, split as pysparksplit, array_contains, desc, col, length, when
from pyspark.ml.feature import QuantileDiscretizer
import os
from pathlib import Path
import shutil

class DataCleaner:
    """A class that provides methods for cleaning, preparing, and exporting a PySpark dataframe. """

    def __init__(self, sqlContext):
        """Instantiates a DataCleaner object using a PySpark sqlContext.

        :param sqlContext: the PySpark sqlContext for the DataCleaner to use in its operations

        """
        self.sqlContext = sqlContext

    def read_csv(self, filepath):
        """Produces a PySpark dataframe based on the contents of the specified comma-separated values (CSV) file.

        :param filepath: path to the CSV file to read
        :returns: the PySpark dataframe generated from the CSV file
        """
        return(self.sqlContext.read.csv(filepath, header=True, inferSchema=True))

    def drop_na_values(self, dataframe, field_names):
        """Produces a PySpark dataframe without records from the provided dataframe that contain null values in any specified fields.

        :param dataframe: the PySpark dataframe
        :param field_names: the fields to search for null values
        :returns: the PySpark dataframe from which records with null values in the specified fields have been removed
        """
        return(dataframe.na.drop(how='any',thresh=None,subset=field_names))

    def zero_out_na_values(self, dataframe):
        """Produces a PySpark dataframe with zeros replacing all null values in the provided dataframe.

        :param dataframe: the PySpark dataframe
        :returns: the PySpark dataframe in which null values have been replaced with zeros
        """
        # Replace nulls with 0
        return(dataframe.na.fill(0))

    def fix_data_type(self, dataframe, field_names, data_type):
        """Produces a PySpark dataframe in which specified fields have been set to the data type selected.

        :param dataframe: the PySpark dataframe
        :param field_names: the fields to be assigned the new data type
        :param data_type: the new data type to be assigned to the specified fields
        :returns: the PySpark dataframe in which the specified fields have been assigned the new data type
        """
        for field in field_names:
            dataframe = dataframe.withColumn(field, dataframe[field].cast(data_type))
        return(dataframe)

    def create_categorical_feature(self, dataframe, base_field, categorical_field, levels, increment=0):
        """Produces a PySpark dataframe containing a categorical field based on a specified field.

        :param dataframe: the PySpark dataframe
        :param base_field: the field that provides the values used to create the categorical field
        :param categorical_field: the name of the categorical field to be created
        :param levels: the number of levels to be created in the categorical field
        :param increment: the value to add to each level (Default value = 0)
        :returns: the PySpark dataframe containing a categorical field and all fields in the supplied dataframe
        """
        dataframe = self.fix_data_type(dataframe, [base_field], 'double')
        discretizer = QuantileDiscretizer(numBuckets=levels, inputCol=base_field, outputCol=categorical_field)
        dataframe = discretizer.fit(dataframe).transform(dataframe)
        return(dataframe.withColumn(categorical_field, dataframe[categorical_field].cast('int')+increment))

    def show_stats(self,dataframe,batch_size=4):
        """Prints statistics for each column in the PySpark dataframe, such as the count, mean, stddev, min, and max.

        :param dataframe: the PySpark dataframe
        :param batch_size: the number of columns to show on one row of output (Default value = 4)
        """
        chunks = len(dataframe.columns) // batch_size + 1
        for i in range(chunks):
            dataframe.select(dataframe.columns[i*batch_size:(i+1)*batch_size]).describe().show()

    def set_tag_count(self, dataframe, base_field, count_field):
        """Produces a PySpark dataframe containing a column representing the number of tags in each record.

        :param dataframe: the PySpark dataframe
        :param base_field: the column to be searched for tags
        :param count_field: the name of the new column to store the number of tags
        :returns: the PySpark dataframe containing the field with tag count and all fields in the supplied dataframe
        """
        def count_tags(string):
            """Counts the number of tags in a string based on a standard separator, the pipe character.

            :param string: the string that may contain tags
            :returns: the number of tags found
            """
             # Count tags based on the number of separators found
            if string is not None:
                return string.count('|') + 1
            return 0

        tag_counter = udf(count_tags)
        return(dataframe.withColumn(count_field, tag_counter(dataframe[base_field])))

    def create_tag_frequencies(self, dataframe):
        """Produces a PySpark dataframe containing a column representing the total frequency of the tags by record.

        The frequency of tags is determined by their proportion of the total number of tags in the dataframe.

        :param dataframe: the PySpark dataframe
        :returns: the PySpark dataframe containing the tag frequency field and all fields in the supplied dataframe
        """
        df_tags = dataframe.selectExpr("tag1 AS tag").union(dataframe.selectExpr("tag2 AS tag")).union(dataframe.selectExpr("tag3 AS tag")) \
                           .union(dataframe.selectExpr("tag4 AS tag")).union(dataframe.selectExpr("tag5 AS tag"))
        df_tags = df_tags.na.drop(subset=["tag"])
        tags_total_count = df_tags.count()
        print("Total number of tags used, including duplicates:",tags_total_count)
        df_tag_freq = df_tags.groupBy("tag").count().orderBy(desc("count"))
        df_tag_freq = df_tag_freq.withColumn("frequency", col("count")/tags_total_count)
        df_tag_freq.orderBy(desc("frequency")).show(10)

        def one_hot_encode_top_n_tags(dataframe,n):
            """Produces a PySpark dataframe containing columns indicating whether each of the top n tags are present.

            :param dataframe: the PySpark dataframe 
            :param n: the number of the top ranked tags to return as tag fields
            :returns: the PySpark dataframe containing the top n tag fields and all fields in the supplied dataframe
            """
            top_n = [t.tag for t in df_tag_freq.orderBy(desc("frequency")).select("tag").limit(n).collect()]
            for tag in top_n:
                # replace tag name ".net" with "dotnet", for example, to avoid problems with periods in tag names
                tag_column_name = ("tag_"+tag).replace(".","dot")
                dataframe = dataframe.withColumn(tag_column_name, array_contains(dataframe.tags_split, tag).cast("int"))
            return dataframe

        dataframe = one_hot_encode_top_n_tags(dataframe,20)
        tag_columns = [col for col in dataframe.columns if col.startswith('tag')]

        print("Tag-related columns")
        dataframe.select(tag_columns).show(10,False)

        dataframe.createOrReplaceTempView('df')
        df_tag_freq.createOrReplaceTempView('df_tag_freq')

        for n in range(1,6):
            dataframe = self.sqlContext.sql("SELECT df.*, df_tag_freq.frequency AS frequency_tag{} FROM df LEFT JOIN df_tag_freq ON df.tag{} = df_tag_freq.tag".format(n,n))
            dataframe = dataframe.na.fill({"frequency_tag{}".format(n): 0})
            dataframe.createOrReplaceTempView('df')

        dataframe = dataframe.withColumn("frequency_sum", col("frequency_tag1")+col("frequency_tag2")+col("frequency_tag3")+col("frequency_tag4")+col("frequency_tag5"))

        # Remove temporary columns
        dataframe = dataframe.select([c for c in dataframe.columns if c not in {"tags_split","tag1","tag2","tag3","tag4","tag5","frequency_tag1","frequency_tag2", \
                                      "frequency_tag3","frequency_tag4","frequency_tag5"}])
        return(dataframe)

    def drop_columns(self, dataframe, field_names):
        """Produces a PySpark dataframe without the specified fields.

        :param dataframe: the PySpark dataframe
        :param field_names: the fields to omit from the PySpark dataframe that is returned
        :returns: the PySpark dataframe without the specified fields
        """
        return(dataframe.select([col for col in dataframe.columns if col not in field_names]))

    def set_years_between_dates(self, dataframe, start_date, end_date, years_between_field):
        """Produces a PySpark dataframe containing a field representing the number of years between two specified fields.

        :param dataframe: the PySpark dataframe
        :param start_date: the field containing the start date to use in calculating the years between fields
        :param end_date: the field containing the end date to use in calculating the years between fields
        :param years_between_field: the name of the field to create
        :returns: the PySpark dataframe containing the new field and all fields in the supplied dataframe
        """
        return(dataframe.withColumn(years_between_field, datediff(dataframe[end_date], dataframe[start_date])/365.25))

    def set_minimum_date(self, dataframe, field_name, minimum_date):
        """Produces a PySpark dataframe without records that precede a minimum date for a specified field.

        :param dataframe: the PySpark dataframe
        :param field_name: the field to filter by date
        :param minimum_date: the minimum date to require in the filter
        :returns: the PySpark dataframe without records preceding the minimum date for the specified field
        """
        return(dataframe.filter("{} >= '{} 00:00:00'".format(field_name, minimum_date)))

    def fill_na(self, dataframe, field_name, fill_value):
        """Produces a PySpark dataframe with null values in the specified field replaced with the stated value.

        :param dataframe: the PySpark dataframe
        :param field_name: the field to search for null values
        :param fill_value: the value to replace the null values
        :returns: the PySpark dataframe containing the stated value in place of null values found in the supplied dataframe
        """
        return(dataframe.na.fill({field_name: fill_value}))

    def create_binary_feature(self, dataframe, base_field, binary_field):
        """Produces a PySpark dataframe containing a field that is 0 or 1.

        The value of the binary field will be 1 if the value of the evaluated field is greater than 0; otherwise it will be 0.

        :param dataframe: the PySpark dataframe
        :param base_field: the field to use as the basis for the binary field
        :param binary_field: the name to give to the field that will contain values of 0 or 1
        :returns: the PySpark dataframe containing the binary field and all fields in the supplied dataframe.
        """
        return(dataframe.withColumn(binary_field, when(dataframe[base_field] > 0, 1).otherwise(0)))

    def create_length_feature(self, dataframe, base_field, length_field):
        """Produces a PySpark dataframe containing a field representing the length of a specified string field.

        :param dataframe: the PySpark dataframe
        :param base_field: the string field for which length is to be calculated
        :param length_field: the name to give to the field that will contain the length of the base_field
        :returns: the PySpark dataframe containing the length field and all fields in the supplied dataframe.
        """
        return(dataframe.withColumn(length_field, length(dataframe[base_field])))

    def create_tag_columns(self, dataframe, base_field, max_tag_count):
        """Produces a PySpark dataframe containing numbered tag fields and a tags_split field with tags in a list.

        :param dataframe: the PySpark dataframe
        :param base_field: the field containing tags separated by a pipe character
        :param max_tag_count: the number of tag fields to create
        :returns: the PySpark dataframe containing the new tag fields and all fields in the supplied dataframe.
        """
        split_col = pysparksplit(dataframe[base_field], '\|')
        dataframe = dataframe.withColumn('tags_split', split_col)
        for i in range(0, max_tag_count):
            dataframe = dataframe.withColumn('tag'+str(i+1), split_col.getItem(i))
        return(dataframe)

    def create_levels_column(self, dataframe, base_field, levels_field):
        """Produces a PySpark dataframe containing a field based on the level of a specified field

        The level will be:
        0 if the value in the specified column is an integer less than 1
        1 if the value in the specified column is an integer between 1 and 2
        2 if the value in the specified column is an integer between 3 and 4
        3 if the value in the specified column is an integer that is 5 or greater

        :param dataframe: the PySpark dataframe
        :param base_field: the field containing integers to use to determine the level
        :param levels_field: the name of the field that will contain the levels
        :returns: the PySpark dataframe containing the levels field and all fields in the supplied dataframe
        """
        return(dataframe.withColumn(levels_field, when(dataframe[base_field].between(1,2), 1) \
                        .when(dataframe[base_field].between(3,4), 2).when(dataframe[base_field] >= 5, 3).otherwise(0)))

    def create_valence_column(self, dataframe, base_field, valence_field):
        """Produces a PySpark dataframe containing a field that is -1, 0, or 1 depending on the value of a specified field.

        The valence will be:
        -1 if the value in the specified column is negative
        0 if the value in the specified column is zero
        1 if the value in the specified column is positive

        :param dataframe: the PySpark dataframe
        :param base_field: the field containing values to use to determine the valence
        :param valence_field: the name of the field that will contain the valence
        :returns: the PySpark dataframe containing the valence field and all fields in the supplied dataframe
        """
        return(dataframe.withColumn(valence_field, when(dataframe[base_field] < 0, -1).when(dataframe[base_field] > 0, 1).otherwise(0)))

    def show_record_count(self, dataframe):
        """Prints the number of records in the supplied PySpark dataframe.

        :param dataframe: the PySpark dataframe
        """
        print("Number of records:",dataframe.count())

    def show_field_names(self, dataframe):
        """Prints a list containing pairs of each field names and its data type for the supplied PySpark dataframe.

        :param dataframe: the PySpark dataframe
        """
        print("Fields:", list(zip((f.name for f in dataframe.schema.fields), (f.dataType for f in dataframe.schema.fields))))

    def write_output(self,dataframe,path):
        """Stores a PySpark dataframe in one or more CSV files in the specified path.

        :param dataframe: the PySpark dataframe
        :param path: the path to which the contents of the dataframe should be written
        """
        if(os.path.isdir(path)):
            print("{} already exists, but will be deleted.".format(path))
            # Delete previous output file
            shutil.rmtree(path)
            print("Deleted folder {}".format(path))
        dataframe.write.csv(path, header=True)
        print("Saved results to {}".format(path))


