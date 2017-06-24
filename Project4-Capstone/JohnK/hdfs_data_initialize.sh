#!/bin/bash

# Script to initialize data into HDFS



# Copy bitcoin data to HDFS
hadoop fs -mkdir /user/hadoop/bitcoin/
hadoop fs -put /tmp/bitcoin.csv /user/hadoop/bitcoin

# Copy eth data to HDFS
#hadoop fs -mkdir /user/hadoop/ethereum/
#hadoop fs -put /tmp/ethereum.csv /user/hadoop/ethereum


# Add any number of cryptocurrencies as wanted