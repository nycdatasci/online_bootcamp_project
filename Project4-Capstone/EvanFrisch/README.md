## Stack Overflow Outcome Prediction

#### About the Stack Overflow Public Dataset

[Stack Overflow](https://stackoverflow.com), the leading open question 
and answer website for computer programming questions, periodically 
publishes the contents of its database, including questions, answers, 
comments, and users, since its launch in 2008. This data is available
in multiple formats, including as a public dataset on Google BigQuery,
an enterprise data warehouse on Google Cloud Platform.

#### Project Overview

This project draws data from the Stack Overflow public dataset, and uses
it to make predictions of outcomes on the Stack Overflow website. It then
presents results in a web application that takes the form of a game called
Stack Overlord, which challenges people to compete with machine learning
models by making predictions of their own.

* **Pipeline** (found in so-pipeline folder)
  * **Extraction** of relevant data from Stack Overflow public dataset
  * **Preprocessing** of data using Apache Spark
  * **Prediction** of outcomes on Stack Overflow using H2O machine learning 
library
  * **Loading** of results to Amazon Web Services S3 cloud storage.
* **Web Application** (found in so-predict folder)
  * **Acquisition** of results of pipeline from S3.
  * **Presentation** of selected data (on Stack Overflow questions and users) as 
challenges to visitors to make predictions
  * **Evaluation and scoring** of visitors' predictions in comparison with those 
of machine learning models.

Please see the blog post (coming soon to https://blog.nycdatascience.com) for
more details.
