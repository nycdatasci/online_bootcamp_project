import json
import boto3

# Create S3 bucket if it does not exist already
s3 = boto3.resource('s3')
bucket_name = 'so_predict'
s3.create_bucket(Bucket=bucket_name)

# Dictionary mapping local filenames to the filenames to use in S3 bucket
fileDict = { 'test_with_combined_qf_predictions.json': 'questions_qf.json', 'quantile_metrics_questions.json': 'questions_quantiles.json', 
             'test_with_predictions_rq_gbm.json': 'users_rq.json', 'quantile_metrics_users.json': 'users_quantiles.json' }

def upload_file_to_bucket(json_path = 'json', filename_local, filename_s3, bucket_name):
    """Stores the specified file to an S3 bucket using the name provided

    :param json_path: the relative path to the local file (Default value = 'json')
    :param filename_local: the name of the local file to upload to S3
    :param filename_s3: the filename to write to S3
    :param bucket_name: the name of the S3 bucket in which to store the file
    """
    # Read in the contents of the json file from the local filesystem
    data = []
    with open(json_path+'\'+filename_local) as json_data:
        data = json.load(json_data)

    # Write the contents to a json file in the S3 bucket
    s3 = boto3.resource('s3')
    obj = s3.Object(bucket_name,filename_s3)
    obj.put(Body=json.dumps(data))

# Upload each file to the S3 bucket
for filename_local, filename_s3 in fileDict.items():
    upload_file_to_bucket(filename_local=filename_local, filename_s3=filename_s3, bucket_name=bucket_name)
