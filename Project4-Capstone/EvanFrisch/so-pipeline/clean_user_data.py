sc.addPyFile("/home/ubuntu/data_utilities/data_cleaner.py")
from data_cleaner import DataCleaner

# Create DataCleaner object and read input file
dc = DataCleaner(sqlCtx)
df = dc.read_csv("/home/ubuntu/csv/so_bq_users.csv")

# Remove records that lack a user_id, user_display_name, user_reputation, questions_count, answers_count, or comments_count
df = dc.drop_na_values(dataframe=df, field_names=["user_id","user_display_name","user_reputation","questions_count","answers_count","comments_count"])

print(df.printSchema())

# Create categorical feature user_reputation_quantile from user_reputation
df = dc.create_categorical_feature(dataframe=df, base_field="user_reputation", categorical_field="user_reputation_quantile", levels=5, increment=1)

print("Number of records:", df.count())

# Show count, min, max, etc. for up to 4 columns at a time
dc.show_stats(dataframe=df, batch_size=4)

# Export output to file
#dc.write_output("file:///home/ubuntu/csv/BigQueryUserOutputCleaner.csv")
dc.write_output(dataframe=df, path="/home/ubuntu/csv/BigQueryUserOutputCleaner.csv")
print("Completed clean_user_data.py")
exit(0)
