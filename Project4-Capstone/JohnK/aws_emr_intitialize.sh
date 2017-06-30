#!/bin/bash

## Below EMR cluster configuration for sparky


# aws command line interface (awscli) required to be installed

# make sure aws account keys are already set up in awscli and security policy
# roles are already defined for online account (ie. in this script:EMR_EC2_DefaultRole)

# Modify instance machine types and count for more powerful cluster

aws emr create-cluster --applications Name=Hadoop Name=Spark Name=Hive Name=Pig Name=Tez Name=Ganglia \
--release-label emr-5.2.0 --name "EMR 5.2.0 RStudio + sparklyr, smaller" --service-role EMR_DefaultRole \
--instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m3.xlarge \
InstanceGroupType=CORE,InstanceCount=5,InstanceType=m3.xlarge --bootstrap-actions \
Path=s3://ionglyph.emr/config/rstudio_sparklyr_emr5.sh,\
Args=["--rstudio","--shiny","--sparkr","--rexamples","--plyrmr","--rhdfs","--sparklyr"],\
Name="Install RStudio" --ec2-attributes InstanceProfile=EMR_EC2_DefaultRole,KeyName=rstatsVM \
--configurations '[{"Classification":"spark","Properties":{"maximizeResourceAllocation":"true"}}]' \
--region us-east-1