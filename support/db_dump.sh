#!/bin/bash
set -e
set -x
CVS=${EXPORT_DIR:?}/support/cvs

# set path to main postgresql database only when it is not already set
PGDATA=${PGDATA:?} # typically '/var/lib/postgresql/data'

# abort if database files do not exist
if [ ! -f $PGDATA/PG_VERSION ]; then
  ls -l $PGDATA
  echo "Aborting $0: Data files not found"
  exit 0
fi

# ensure that path ${EXPORT_DIR}/backup exists and is owned by galaxy
if [ ! -d ${EXPORT_DIR}/backup ]; then
  mkdir -p ${EXPORT_DIR}/backup
  chown galaxy:galaxy ${EXPORT_DIR}/backup
fi

# ensure that path ${EXPORT_DIR}/backup/pg exists and is owned by postgres
if [ ! -d ${EXPORT_DIR}/backup/pg ]; then
  mkdir -p ${EXPORT_DIR}/backup/pg
  chown postgres ${EXPORT_DIR}/backup/pg
fi

# init CVS repository at ${EXPORT_DIR}/backup/pg, if necessary, as postgres
cd ${EXPORT_DIR}/backup/pg
if [ ! -d CVSROOT ]; then
  su -l -c "${CVS} -d ${EXPORT_DIR}/backup/pg init"  postgres
fi
if [ ! -d dumpall ]; then
  su -l -c "mkdir ${EXPORT_DIR}/backup/pg/dumpall" postgres
fi

# As root, make sure that:
#   - the dumpall directory is empty with proper permissions
if [ -d ${EXPORT_DIR}/dumpall ]; then
  rm -rf ${EXPORT_DIR}/dumpall
fi
mkdir ${EXPORT_DIR}/dumpall
chown -R postgres:postgres ${EXPORT_DIR}/dumpall

# initialize sandbox;
#   dump db and add or update files;
#   commit
su -l -c "
  ${CVS} -d ${EXPORT_DIR}/backup/pg co -d ${EXPORT_DIR}/dumpall dumpall
  echo '\\set ON_ERROR_STOP 0' > ${EXPORT_DIR}/dumpall/pg_dumpall.sql
  pg_dumpall >> ${EXPORT_DIR}/dumpall/pg_dumpall.sql
  sed -i -e '"'/-- Database creation/a \
\\set ON_ERROR_STOP 1'"' ${EXPORT_DIR}/dumpall/pg_dumpall.sql
  cd ${PGDATA}
  cp *.conf ${EXPORT_DIR}/dumpall
  cd ${EXPORT_DIR}/dumpall
  echo '"'#!/bin/bash
  echo "Initializing galaxy database with defaults"
  "${psql[@]}" < /docker-entrypoint-initdb.d/init-galaxy-db.sql.in
  echo "Successfully initialized galaxy database"
  '"'> ${EXPORT_DIR}/dumpall/init-galaxy-db.sh
  chmod +x ${EXPORT_DIR}/dumpall/init-galaxy-db.sh
  ${CVS} add *.conf pg_dumpall.sql init-galaxy-db.sh
  ${CVS} commit -m 'Database file-backup - $(date)'
  grep pg_dumpall.sql CVS/Entries
" postgres
