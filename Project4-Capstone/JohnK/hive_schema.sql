
# Create metadata for bitcoin
CREATE EXTERNAL TABLE IF NOT EXISTS bitcoin
(
unixtime int,
price double,
amount double,
trade     int
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES
(
"separatorChar" = '\,',
"quoteChar"     = '\"'
)
STORED AS TEXTFILE
tblproperties("skip.header.line.count"="1");

# Load data into table
LOAD DATA INPATH '/user/hadoop/bitcoin' INTO TABLE bitcoin;