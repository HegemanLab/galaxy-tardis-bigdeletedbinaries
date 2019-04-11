#!/bin/bash
set -e
set -x
# set path to main postgresql database only when it is not already set
PGDATA=${PGDATA:-/var/lib/postgresql/data}

# create logical link to cvs executable if it does not already exist
if [ ! -h /usr/local/bin/cvs ]; then
  ln -s /export/support/cvs /usr/local/bin/cvs
fi

# ensure that path /export/backup/pg exists and is owned by postgres
if [ ! -d /export/backup ]; then mkdir /export/backup; fi
if [ ! -d /export/backup/pg ]; then mkdir /export/backup/pg; fi
cd /export/backup/pg
chown postgres .

# init CVS repository at /export/backup/pg, owned by postgres
if [ ! -d CVSROOT ]; then su -l -c 'cvs -d /export/backup/pg init' postgres; fi
if [ ! -d dumpall ]; then su -l -c 'mkdir /export/backup/pg/dumpall' postgres; fi

# abort if database files do not exist
if [ ! -f $PGDATA/postgresql.conf ]; then
  echo $PGDATA contains
  ls $PGDATA
  exit 0
fi

# initialize sandbox if necessary
if [ ! -d $PGDATA/CVS ]; then su -l -c "cd $PGDATA; cvs -d /export/backup/pg co -d . dumpall" postgres; fi

# add files if necessary
#   Note that the psql -c "select 1" | cat` statement will fail and abort the script when postgresql is not connectable
if [ ! -f $PGDATA/pg_dumpall.sql ]; then 
  su -l -c "
    cd $PGDATA
    set -e
    psql -c 'select 1' | cat
    pg_dumpall > pg_dumpall.sql
    cvs add *.conf pg_dumpall.sql
    cvs commit -m 'first commit of database files for backup - $(date)'
  " postgres
else
  su -l -c "
    cd $PGDATA
    set -e
    # this statement will fail and abort the script postgresql is not connectable
    psql -c 'select 1' | cat
    pg_dumpall > pg_dumpall.sql
    cvs update
    cvs commit -m 'update of database files for backup - $(date)'
  " postgres
fi
 
# delete logical link to cvs executable
if [ -h /usr/local/bin/cvs ]; then
  rm /usr/local/bin/cvs
fi
