## Setup of Stack Overflow Outcome Prediction Pipeline

The Stack Overflow Outcome Prediction pipeline extracts data
from the Stack Overflow public dataset, cleans and preprocesses
that data, builds and applies machine learning models to predict
outcomes, and loads the results into Amazon Web Services (AWS)
S3 cloud storage.

Create an AWS account or login to an existing one. Then, create
an EC2 instance running Ubuntu 16.04. An instance size of 
t2.2xlarge may be needed, depending on the amount of data 
specified in the pipeline parameters.

Install Python 3.5.2 on Ubuntu.

Install [PySpark 2.2.0](https://pypi.python.org/pypi/pyspark):

pip install pyspark

Install the [H2O machine learning library](http://h2o-release.s3.amazonaws.com/h2o/rel-weierstrass/7/index.html),
version 3.14.0.1. The pipeline code assumes that it will be
installed in /home/ubuntu/h2o-3.14.0.1.

On Google Cloud Platform, create a Cloud Platform project as 
described in [Google's documentation](https://cloud.google.com/bigquery/quickstart-web-ui).

In Ubuntu, install the [Google Cloud SDK](https://cloud.google.com/sdk/docs/#deb),
which provides the bq command line tool that the pipeline uses
to extract data from BigQuery.

Clone the repository to Ubuntu on AWS to copy the files from the 
so-pipeline folder, which contain the code to extract data using 
BigQuery, preprocess data using PySpark, predict outcomes using H2O,
and export results to S3. 

Specify the preferred start and end dates for the collection
of question and user data from the Stack Overflow public dataset
in so_pipeline.sh.

Set the name of the S3 bucket to use in upload_results_to_s3.py.

Run the pipeline from the command line:

./so_pipeline.sh
