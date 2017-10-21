sc.addPyFile("/home/ubuntu/data_utilities/data_cleaner.py")
from data_cleaner import DataCleaner

# Read input file and create DataCleaner object
dc = DataCleaner(sqlCtx)

df = dc.read_csv("/home/ubuntu/csv/so_bq_questions.csv")

# Remove records that lack a question_id, questioner_id, question_body_length, questioner_reputation, or questioner_up_votes
df = dc.drop_na_values(dataframe=df,field_names=["question_id","questioner_id","question_body_length","questioner_reputation","questioner_up_votes"])

# Fix data types
df = dc.fix_data_type(dataframe=df, field_names=["question_body_length","question_codeblock_count","answer_count","question_comment_count","questioner_id","questioner_up_votes",
                      "questioner_down_votes","accepted_answer_id","questioner_reputation","questioner_views","max_answer_score"], data_type='int')

df = dc.fix_data_type(dataframe=df, field_names=["questioner_account_creation_date","min_answer_creation_date"], data_type="timestamp")

df = dc.set_tag_count(dataframe=df, base_field="question_tags", count_field="question_tags_count")

df = dc.set_years_between_dates(dataframe=df, start_date="questioner_account_creation_date", end_date="question_creation_date", years_between_field="questioner_years_since_joining")

df = dc.fill_na(dataframe=df, field_name="question_favorite_count", fill_value=0)

# Create categorical feature question_view_quantile from question_view_count
df = dc.create_categorical_feature(dataframe=df, base_field="question_view_count", categorical_field="question_view_quantile", levels=10, increment=0)

df = dc.create_binary_feature(dataframe=df, base_field="question_favorite_count", binary_field="question_favorited")
df = dc.create_binary_feature(dataframe=df, base_field="answer_count", binary_field="has_answer")

df.select("answer_count","has_answer").show(20)

df = dc.create_length_feature(dataframe=df, base_field="question_title", length_field="question_title_length")

df = dc.create_tag_columns(dataframe=df, base_field="question_tags", max_tag_count=5)

df.select("question_tags","question_tags_count","tags_split","tag1","tag2","tag3","tag4","tag5").show(10)

df = dc.create_levels_column(dataframe=df, base_field="question_comment_count", levels_field="question_comment_level")

df = dc.create_valence_column(dataframe=df, base_field="question_score", valence_field="question_score_level")

df.select("question_comment_count","question_comment_level").show(20)
df.select("question_score","question_score_level").show(20)

df = dc.create_tag_frequencies(dataframe=df)

df = dc.drop_columns(dataframe=df, field_names=["questioner_location"])

df = dc.zero_out_na_values(dataframe=df)

# See how many questions came from people who reportedly have been on Stack Overflow since before it was created
print("Number of questioners with account created too early:", df.filter("questioner_account_creation_date < '2008-09-15 00:00:00'").count())

# Exclude questions from people whose account creation dates are missing or precede the founding of Stack Overflow
so_creation_date = "2008-09-15"
df = dc.set_minimum_date(dataframe=df, field_name="questioner_account_creation_date", minimum_date=so_creation_date)

# See how many questions came from people who reportedly have been on Stack Overflow since before it was created
print("Number of questioners with account created too early:", df.filter("questioner_account_creation_date < '2008-09-15 00:00:00'").count())

# Show count, min, max, etc. for up to 4 columns at a time
dc.show_stats(dataframe=df, batch_size=4)

df.select("question_id","question_title","question_view_count","question_view_quantile").show(10)

dc.show_record_count(dataframe=df)

dc.show_field_names(dataframe=df)

dc.write_output(dataframe=df, path="/home/ubuntu/csv/BigQueryQuestionOutputCleaner.csv")
print("Completed clean_question_data.py")

exit(0)

#df = df.withColumn("question_body_length", df.question_body_length.cast('int'))
#df = df.withColumn("question_codeblock_code", df.question_codeblock_count.cast('int'))
#df = df.withColumn("answer_count", df.answer_count.cast('int'))
#df = df.withColumn("question_comment_count", df.question_comment_count.cast('int'))
#df = df.withColumn("questioner_id", df.questioner_id.cast('int'))
#df = df.withColumn("questioner_up_votes", df.questioner_up_votes.cast('int'))
#df = df.withColumn("questioner_down_votes", df.questioner_down_votes.cast('int'))
#df = df.withColumn("accepted_answer_id", df.accepted_answer_id.cast('int'))
#df = df.withColumn("questioner_reputation", df.questioner_reputation.cast('int'))
#df = df.withColumn("questioner_account_creation_date", df.questioner_account_creation_date.cast('timestamp'))
#df = df.withColumn("questioner_views", df.questioner_views.cast('int'))
#df = df.withColumn("min_answer_creation_date", df.min_answer_creation_date.cast('timestamp'))
#df = df.withColumn("max_answer_score", df.max_answer_score.cast('int'))
#df = df.withColumn('questioner_years_since_joining', datediff(df.question_creation_date,df.questioner_account_creation_date)/365.25)

# Convert NA values to 0 for question_favorite_count
#df = df.na.fill({'question_favorite_count': 0})


#def count_tags(string):
#    # Count tags based on the number of separators found
#    if string is not None:
#        return string.count('|') + 1
#    return 0

#count_tags = udf(count_tags)

#df = df.withColumn("question_tags_count",count_tags(df.question_tags))

# Create categorical feature question_view_quantile from question_view_count
#discretizer = QuantileDiscretizer(numBuckets=10, inputCol="question_view_count", outputCol="question_view_quantile")
#df = discretizer.fit(df).transform(df)
#df = df.withColumn("question_view_quantile", df.question_view_quantile.cast('int'))
#df.select("question_id","question_title","question_view_count","question_view_quantile").show(10)

#df = df.withColumn("question_favorited",df.question_favorite_count.cast('boolean').cast('int'))
#df = df.withColumn("question_favorited", when(df.question_favorite_count > 0, 1).otherwise(0))
#df = df.withColumn("question_title_length",length(df.question_title))

#df = df.withColumn("has_answer", when(df.answer_count > 0, 1).otherwise(0))
#df = df.withColumn("question_comment_level", when(df.question_comment_count.between(1,2), 1).when(df.question_comment_count.between(3,4), 2).when(df.question_comment_count >= 5, 3).otherwise(0))
#df = df.withColumn("question_score_level", when(df.question_score < 0, -1).when(df.question_score > 0, 1).otherwise(0))

#df.select("answer_count","has_answer").show(20)
#df.select("question_comment_count","question_comment_level").show(20)
#df.select("question_score","question_score_level").show(20)

#split_col = pysparksplit(df['question_tags'], '\|')
#df = df.withColumn('tags_split', split_col)
#df = df.withColumn('tag1', split_col.getItem(0))
#df = df.withColumn('tag2', split_col.getItem(1))
#df = df.withColumn('tag3', split_col.getItem(2))
#df = df.withColumn('tag4', split_col.getItem(3))
#df = df.withColumn('tag5', split_col.getItem(4))


#df.select("question_tags","question_tags_count","tags_split","tag1","tag2","tag3","tag4","tag5").show(10)

#print("Number of records:",df.count())

#types = [f.dataType for f in df.schema.fields]
#print("types:",types)


# df.groupBy("tag1").count().orderBy(desc("count")).show(10)

#df_tags = df.selectExpr("tag1 AS tag").union(df.selectExpr("tag2 AS tag")).union(df.selectExpr("tag3 AS tag")).union(df.selectExpr("tag4 AS tag")).union(df.selectExpr("tag5 AS tag"))
#df_tags = df_tags.na.drop(subset=["tag"])
#tags_total_count = df_tags.count()
#print("Total number of tags used, including duplicates:",tags_total_count)
#df_tag_freq = df_tags.groupBy("tag").count().orderBy(desc("count"))
## df_tag_freq.show(10)
#df_tag_freq = df_tag_freq.withColumn("frequency", col("count")/tags_total_count)
#df_tag_freq.orderBy(desc("frequency")).show(10)


#def one_hot_encode_top_n_tags(df,n):
#    top_n = [t.tag for t in df_tag_freq.orderBy(desc("frequency")).select("tag").limit(n).collect()]
#    #print("top_n:",top_n)
#    for tag in top_n:
#        tag_column_name = ("tag_"+tag).replace(".","_")
#        df = df.withColumn(tag_column_name, array_contains(df.tags_split, tag).cast("int"))

#    return df

#df = one_hot_encode_top_n_tags(df,20)
#tag_columns = [col for col in df.columns if col.startswith('tag')]

#print("Tag-related columns")
#df.select(tag_columns).show(10,False)


#df.createOrReplaceTempView('df')
#df_tag_freq.createOrReplaceTempView('df_tag_freq')
#df = sqlContext.sql("SELECT df.*, df_tag_freq.frequency AS frequency_tag1 FROM df LEFT JOIN df_tag_freq ON df.tag1 = df_tag_freq.tag")
#df.createOrReplaceTempView('df')
#df = sqlContext.sql("SELECT df.*, df_tag_freq.frequency AS frequency_tag2 FROM df LEFT JOIN df_tag_freq ON df.tag2 = df_tag_freq.tag")
#df.createOrReplaceTempView('df')
#df = sqlContext.sql("SELECT df.*, df_tag_freq.frequency AS frequency_tag3 FROM df LEFT JOIN df_tag_freq ON df.tag3 = df_tag_freq.tag")
#df.createOrReplaceTempView('df')
#df = sqlContext.sql("SELECT df.*, df_tag_freq.frequency AS frequency_tag4 FROM df LEFT JOIN df_tag_freq ON df.tag4 = df_tag_freq.tag")
#df.createOrReplaceTempView('df')
#df = sqlContext.sql("SELECT df.*, df_tag_freq.frequency AS frequency_tag5 FROM df LEFT JOIN df_tag_freq ON df.tag5 = df_tag_freq.tag")
#df.createOrReplaceTempView('df')

#df = df.na.fill({'frequency_tag1': 0,'frequency_tag2': 0, 'frequency_tag3': 0, 'frequency_tag4': 0, 'frequency_tag5': 0 })

#df = df.withColumn("frequency_sum", col("frequency_tag1")+col("frequency_tag2")+col("frequency_tag3")+col("frequency_tag4")+col("frequency_tag5"))
#df.printSchema()


#df = df.select([c for c in df.columns if c not in {"tags_split","tag1","tag2","tag3","tag4","tag5","frequency_tag1","frequency_tag2","frequency_tag3","frequency_tag4","frequency_tag5"}])

# Save question titles in a separate csv for lookup by question_id
#df.select("question_id","question_title")

# Don't drop the question title since quotes in the title field are not being removed
#df = df.drop("question_title")
#df = df.drop("questioner_location")

# Replace nulls with 0
#df = df.na.fill({'question_body_length': 0, 'question_title_length': 0, 'question_tags_count': 0,'questioner_reputation': 0, 'question_tags_count': 0, 'questioner_years_since_joining': 0})
#df = df.na.fill(0)

#print("Number of records:",df.count())

# Show count, min, max, etc. for up to 4 columns at a time
#batch_size = 4
#chunks = len(df.columns) // batch_size + 1
#for i in range(chunks):
#    df.select(df.columns[i*batch_size:(i+1)*batch_size]).describe().show()

# See how many questions came from people who reportedly have been on Stack Overflow since before it was created
#df.filter("questioner_account_creation_date < '2008-09-15 00:00:00'").count()

# Exclude questions from people whose account creation dates are missing or precede the founding of Stack Overflow
#df_cleaner = df.filter("questioner_account_creation_date >= '2008-09-15 00:00:00'")

# Show the minimum and maximum question code block counts
#print("Minimum and maximum number of code blocks per question:")
#dc.df.select([min('question_codeblock_count'),max('question_codeblock_count')]).show()


# Delete previous output
#os.system("rm -r /home/ubuntu/BigQuerySampleOutputCleaner.csv")
##os.system("rm -r /home/ubuntu/BigQuerySampleOutputCleaner.tsv")
##os.system("mkdir BigQuerySampleOutputCleaner.csv")

#df_cleaner.write.csv("file:///home/ubuntu/BigQuerySampleOutputCleaner.csv", header=True)
##df_cleaner.write.option("sep","\t").option("header","true").csv("file:///home/ubuntu/BigQuerySampleOutputCleaner.tsv")
