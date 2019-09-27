#!/bin/bash

DATABASENAME=$1

if [ -z $DATABASENAME ] ; then
  echo "USAGE: ./$(basename $0) db_name"
  exit 1
fi

for tbl in `psql -qAt -c "select tablename from pg_tables where schemaname = 'public';" $DATABASENAME` ; do  
	echo "vacuum  -> $tbl"
	psql -c "vacuum full analyze \"$tbl\" " $DATABASENAME ;
	echo "reindex -> $tbl"
	psql -c "reindex table \"$tbl\" " $DATABASENAME ;
done