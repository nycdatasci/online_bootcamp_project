#!/bin/bash
cd ~/sparktest
source sparktest/bin/activate
PYTHONSTARTUP=/home/ubuntu/clean_question_data.py pyspark
