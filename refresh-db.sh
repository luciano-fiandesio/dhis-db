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
# This will create a database with the name 'dhis2_2_32'
#
# It is possible to pass the database name as second argument:
#
#
# ./refresh-db.sh 2.32 test_2_32
#

set -e
set -u

DB_VERSION=$1

if [[ -z $DB_VERSION ]];
then
	echo "Please, specify a DHIS2 database version (2.33, 2.32, etc.)"
	exit 2
fi

DB_NAME=${2:-dhis2_${1/./_}}


tmp_dir=$(mktemp -d)
url=https://raw.githubusercontent.com/dhis2/dhis2-demo-db/master/sierra-leone/$1/dhis2-db-sierra-leone.sql.gz

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

DROP DATABASE IF EXISTS $DB_NAME;

CREATE DATABASE $DB_NAME;

GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO dhis;

\c $DB_NAME

CREATE EXTENSION postgis;

\q

END_OF_SCRIPT

psql $DB_NAME < $tmp_dir/dhis2-db-sierra-leone.sql

rm -fr $tmp_dir

echo "done!"
