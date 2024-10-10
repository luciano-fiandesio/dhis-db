#!/bin/bash
#
# Fetches a database dump from https://github.com/dhis2/dhis2-demo-db/tree/master/sierra-leone
# or uses a local file if provided, and restores it on a local postgres instance.
# The newly created database has the following name: dhis2_2_32 (assuming 2.32 was passed)
# Arguments:
#
# - db version (2.33, 2.32, etc) or 'file:<local-path>'
#
# USAGE:
#
# ./refresh-db.sh 2.32
# ./refresh-db.sh file:~/test/db.sql.gz
#
# This will create a database with the name 'dhis2_2_32' or use the local file for restoration.
#
# It is possible to pass the database name as a second argument:
#
# ./refresh-db.sh 2.32 test_2_32
# ./refresh-db.sh file:~/test/db.sql.gz test_2_32
#

set -e
set -u

DB_SOURCE=$1

if [[ -z $DB_SOURCE ]]; then
	echo "Please, specify a DHIS2 database version (2.39, 2.40, etc.) or a local file path with 'file:<path>'"
	exit 2
fi

# Determine if a local file is being used
if [[ $DB_SOURCE == file:* ]]; then
	LOCAL_FILE="${DB_SOURCE#file:}"
	DB_NAME=${2:-dhis2_local}
	# Expand the tilde (~) if present
	LOCAL_FILE="${LOCAL_FILE/#\~/$HOME}"

	# Ensure the file exists
	if [[ ! -f "$LOCAL_FILE" ]]; then
		echo "The specified file does not exist: $LOCAL_FILE"
		exit 2
	fi

	# Unzip the file if it has a .gz extension, otherwise use it directly if it's a .sql file
	if [[ $LOCAL_FILE == *.gz ]]; then
		gunzip -c "$LOCAL_FILE" > "${LOCAL_FILE%.gz}"
		LOCAL_FILE="${LOCAL_FILE%.gz}"
	elif [[ $LOCAL_FILE != *.sql ]]; then
		echo "Unsupported file type. Please provide a .sql or .sql.gz file."
		exit 2
	fi
else
	DB_VERSION=$DB_SOURCE
	DB_NAME=${2:-dhis2_${DB_VERSION//./_}}
	tmp_dir=$(mktemp -d)
	url=https://databases.dhis2.org/sierra-leone/$DB_VERSION/dhis2-db-sierra-leone.sql.gz

	if ! wget -q --method=HEAD $url; then
		echo "There is no database with version: ${DB_VERSION}"
		exit 2
	fi

	# Fetch the database
	wget -P $tmp_dir $url
	gunzip $tmp_dir/dhis2-db-sierra-leone.sql.gz
	LOCAL_FILE="$tmp_dir/dhis2-db-sierra-leone.sql"
fi

# Create the database
psql postgres << END_OF_SCRIPT

DROP DATABASE IF EXISTS $DB_NAME;

CREATE DATABASE $DB_NAME;

GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO dhis;

\c $DB_NAME

CREATE EXTENSION postgis;

\q

END_OF_SCRIPT

# Restore the database
psql $DB_NAME < "$LOCAL_FILE"

# Clean up if a temporary directory was used
if [[ -n "${tmp_dir:-}" ]]; then
	rm -fr $tmp_dir
fi

echo "done!"
