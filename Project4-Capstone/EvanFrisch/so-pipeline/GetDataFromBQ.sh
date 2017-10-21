#!/bin/bash
OUTPUTFILE=$1
SQLFILE=$2
STARTDATE=$3
ENDDATE=$4
bq query -q --headless --format=csv --use_legacy_sql=false --max_rows=10000000 --parameter start_date:TIMESTAMP:$STARTDATE --parameter end_date:TIMESTAMP:$ENDDATE > ~/$OUTPUTFILE "$(< ${SQLFILE})"
