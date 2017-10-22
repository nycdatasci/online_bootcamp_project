## Setup of Stack Overlord Web Application

The Stack Overlord game is a web application built using Flask and 
designed to run on Amazon Web Services (AWS) Lambda serverless 
computing platform.

Clone the repository to copy the files from the so-predict folder,
which contain the web application, to your preferred development
environment. Your environment should have Python 3.6.2 installed.

Install Boto, a library that enables Python to interact with Amazon
Web Services: 

pip install boto

Create an AWS account or login to an existing one. In IAM, create a
new user with programmatic access. 

Save your AWS access key and secret access key to a file called
credentials in a .aws folder inside your home folder. If you do not
have an AWS config file already, save a file called config in the
same .aws folder to specify, at a minimum, the AWS region to use.

Examples of the format of the credentials and config files
are found in the [AWS Command Line Interface documentation](http://docs.aws.amazon.com/cli/latest/userguide/cli-config-files.html).

Use virtualenv to create an isolated environment for the development
of the web application. It can be installed using: 

pip install virtualenv

After activating the virtual environment, install [Zappa](https://github.com/Miserlou/Zappa), a library 
that facilitates building Python applications for AWS Lambda: 

pip install zappa

Also install Flask, Flask Bootstrap, and Flask Nav using pip.

Open the zappa-settings.json file and enter the name of the app 
(for app_function) and the name of the S3 bucket to use (for 
s3_bucket).

To deploy the web application to AWS Lambda in development, use the
command: 

zappa deploy dev

Go to the URL found in the response from Zappa to visit the web
application in your web browser.

More information about using Flask with AWS Lambda can be found in 
this [blog post](https://bitsvsbytes.com/creating-a-microservice-with-flask-zappa-amazon-webservices),
which informed these setup notes.
