#!/bin/bash
cd ~/sparktest
source sparktest/bin/activate
PYTHONSTARTUP=/home/ubuntu/clean_user_data.py pyspark
