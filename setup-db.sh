#!/bin/sh
#
# Creates a Postgres role 'dhis' required for restoring DHIS2 databases from 
# https://github.com/dhis2/dhis2-demo-db/tree/master/sierra-leone

psql postgres << END_OF_SCRIPT

CREATE ROLE dhis WITH SUPERUSER CREATEDB CREATEROLE LOGIN ENCRYPTED PASSWORD 'password';

END_OF_SCRIPT
