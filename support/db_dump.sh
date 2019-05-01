#!/bin/bash
set -e
CVS=/export/support/cvs

# set path to main postgresql database only when it is not already set
PGDATA=${PGDATA:-/var/lib/postgresql/data}

# ensure that path /export/backup exists and is owned by galaxy
if [ ! -d /export/backup ]; then
  if [ -d /export/restore/export/backup ]; then
    mv /export/restore/export/backup /export/backup
  else
    mkdir -p /export/backup
    chown 1450:1450 /export/backup
  fi
fi

# ensure that path /export/backup/pg exists and is owned by postgres
if [ ! -d /export/backup/pg ]; then
  if [ -d /export/restore/export/backup/pg ]; then
    mv /export/restore/export/backup/pg /export/backup/pg
  else
    mkdir -p /export/backup/pg
    chown postgres /export/backup/pg
  fi
fi

# init CVS repository at /export/backup/pg, owned by postgres
cd /export/backup/pg
if [ ! -d CVSROOT ]; then su -l -c "$CVS -d /export/backup/pg init" postgres; fi
if [ ! -d dumpall ]; then su -l -c 'mkdir /export/backup/pg/dumpall' postgres; fi

# abort if database files do not exist
if [ ! -f $PGDATA/PG_VERSION ]; then
  ls -l $PGDATA
  exit 0
fi

# initialize sandbox if necessary
if [ ! -d $PGDATA/CVS ]; then su -l -c "cd $PGDATA; $CVS -d /export/backup/pg co -d . dumpall" postgres; fi

# add files if necessary
#   Note that the psql -c "select 1" | cat` statement will fail and abort the script when postgresql is not connectable
if [ ! -f $PGDATA/pg_dumpall.sql ]; then 
  su -l -c "
    cd $PGDATA
    set -e
    psql -c 'select 1' | cat
    pg_dumpall > pg_dumpall.sql
    $CVS add *.conf pg_dumpall.sql
    $CVS commit -m 'first commit of database files for backup - $(date)'
  " postgres
else
  su -l -c "
    cd $PGDATA
    $CVS update
    set -e
    # this statement will fail and abort the script postgresql is not connectable
    psql -c 'select 1' | cat
    pg_dumpall > pg_dumpall.sql
    $CVS commit -m 'update of database files for backup - $(date)'
  " postgres
fi
 
