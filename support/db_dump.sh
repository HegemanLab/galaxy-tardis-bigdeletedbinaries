#!/bin/bash
set -e

# ensure that path /export/backup/pg exists and is owned by postgres
if [ ! -d /export/backup ]; then mkdir /export/backup; fi
if [ ! -d /export/backup/pg ]; then mkdir /export/backup/pg; fi
cd /export/backup/pg
chown postgres .

# init CVS repository at /export/backup/pg, owned by postgres
if [ ! -d CVSROOT ]; then su -l -c 'cvs -d /export/backup/pg init' postgres; fi
if [ ! -d dumpall ]; then su -l -c 'mkdir /export/backup/pg/dumpall' postgres; fi

# abort if database files do not exist
if [ ! -f /var/lib/postgresql/9.3/main/postgresql.conf ]; then
  echo /var/lib/postgresql/9.3/main contains
  ls /var/lib/postgresql/9.3/main
  exit 0
fi

# initialize sandbox if necessary
if [ ! -d /export/postgresql/9.3/main/CVS ]; then su -l -c 'cd /export/postgresql/9.3/main; cvs -d /export/backup/pg co -d . dumpall' postgres; fi

# add files if necessary
if [ ! -f /export/postgresql/9.3/main/pg_dumpall.sql ]; then 
  su -l -c '
    cd /export/postgresql/9.3/main
    set -e
    # this statement will fail and abort the script postgresql is not connectable
    psql -c "select 1" | cat
    pg_dumpall > pg_dumpall.sql
    cvs add *.conf pg_dumpall.sql
    cvs commit -m "first commit of database files for backup - $(date)"
  ' postgres
 else
  su -l -c '
    cd /export/postgresql/9.3/main
    set -e
    # this statement will fail and abort the script postgresql is not connectable
    psql -c "select 1" | cat
    pg_dumpall > pg_dumpall.sql
    cvs update
    cvs commit -m "update of database files for backup - $(date)"
  ' postgres
 fi
