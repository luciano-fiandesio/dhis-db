#!/bin/bash
#
# Fetches a database dump from https://github.com/dhis2/dhis2-demo-db/tree/master/sierra-leone
# and restores it it on a local postgres instance
# The newly created database has the following name: dhis2_2_32 (assuming 2.32 was passed)
# Arguments:
#
# - db version (2.33, 2.32, etc)
#
# USAGE:
#
# ./refresh-db.sh 2.32
#
set -e
set -u

if [[ $# -ne 1 ]]; then
    echo "Please, specify dhis2 version (2.33, 2.32, etc.)"
    exit 2
fi

tmp_dir=$(mktemp -d)
url=https://raw.githubusercontent.com/dhis2/dhis2-demo-db/master/sierra-leone/$1/dhis2-db-sierra-leone.sql.gz
db_version=${1/./_}
db=dhis2_${db_version}

if ! wget -q --method=HEAD $url;
then
  echo "There is no database with version: " ${1}
  exit 2
fi

# fetch the database
wget -P $tmp_dir $url
gunzip $tmp_dir/dhis2-db-sierra-leone.sql.gz

# create database
psql postgres << END_OF_SCRIPT

DROP DATABASE $db;

CREATE DATABASE $db;

GRANT ALL PRIVILEGES ON DATABASE $db TO dhis;

\c $db

CREATE EXTENSION postgis;

\q

END_OF_SCRIPT

psql $db < $tmp_dir/dhis2-db-sierra-leone.sql

rm -fr $tmp_dir

echo "done!"
