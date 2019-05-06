#!/bin/bash
set -e
set -x
CVS=${EXPORT_DIR:?}/support/cvs

# set path to main postgresql database only when it is not already set
PGDATA=${PGDATA:?} # typically '/var/lib/postgresql/data'

# ensure that path ${EXPORT_DIR}/backup/config exists and is owned by galaxy
if [ ! -d ${EXPORT_DIR}/backup ]; then
  mkdir -p ${EXPORT_DIR}/backup
  chown galaxy:galaxy ${EXPORT_DIR}/backup
fi

# ensure that path ${EXPORT_DIR}/backup/pg exists and is owned by postgres
if [ ! -d ${EXPORT_DIR}/backup/pg ]; then
  mkdir -p ${EXPORT_DIR}/backup/pg
  chown postgres ${EXPORT_DIR}/backup/pg
fi

# init CVS repository at ${EXPORT_DIR}/backup/pg, owned by postgres
cd ${EXPORT_DIR}/backup/pg
if [ ! -d CVSROOT ]; then
  su -l -c "${CVS} -d ${EXPORT_DIR}/backup/pg init"  postgres
fi
if [ ! -d dumpall ]; then
  su -l -c "mkdir ${EXPORT_DIR}/backup/pg/dumpall" postgres
fi

# abort if database files do not exist
if [ ! -f $PGDATA/PG_VERSION ]; then
  ls -l $PGDATA
  exit 0
fi

# initialize sandbox if necessary
su -l -c "
  cd $PGDATA
  if [ ! -d CVS ]; then
    ${CVS} -d ${EXPORT_DIR}/backup/pg co -d . dumpall
  else
    ${CVS} -d ${EXPORT_DIR}/backup/pg update
  fi
" postgres

# add files if necessary
#   Note that the psql -c "select 1" | cat` statement will fail and abort the script when postgresql is not connectable
if [ ! -f $PGDATA/pg_dumpall.sql ]; then 
  su -l -c "
    cd $PGDATA
    set -e
    psql -c 'select 1' | cat
    pg_dumpall > pg_dumpall.sql
    ${CVS} add *.conf pg_dumpall.sql
    ${CVS} commit -m 'first commit of database files for backup - $(date)'
  " postgres
else
  su -l -c "
    cd $PGDATA
    ${CVS} update
    set -e
    # this statement will fail and abort the script postgresql is not connectable
    psql -c 'select 1' | cat
    pg_dumpall > pg_dumpall.sql
    ${CVS} commit -m 'update of database files for backup - $(date)'
  " postgres
fi
 
