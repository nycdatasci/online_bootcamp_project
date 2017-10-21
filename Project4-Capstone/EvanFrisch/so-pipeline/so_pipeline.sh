#!/bin/bash
QUESTIONS_START_DATE="2011-02-01"
QUESTIONS_END_DATE="2011-02-02"
USERS_START_DATE="2013-03-01"
USERS_END_DATE="2013-03-02"
./GetDataFromBQ.sh ./csv/so_bq_questions.csv QueryStackOverflowQuestionsBQ.sql $QUESTIONS_START_DATE $QUESTIONS_END_DATE
./GetDataFromBQ.sh ./csv/so_bq_users.csv QueryStackOverflowUsersBQ.sql $USERS_START_DATE $USERS_END_DATE
./clean_questions.sh
./clean_users.sh
./predict_questions.sh
./predict_users.sh
./upload_results_to_s3.sh
# Exec python scripts using spark-submit 
# $SPARK_HOME/bin/spark-submit
# $SPARK_HOME/bin/spark-submit --py-files /home/ubuntu/data_utilities/data_cleaner.py clean_user_data_submit.py
