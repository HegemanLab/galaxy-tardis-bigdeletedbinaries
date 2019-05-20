#!/bin/bash
echo "$0 - seed or roll back the PostgreSQL database"

last_postgres="$1"
echo '$1='"$1"
if [ ! -z "${last_postgres}"  ]; then
  date -Iseconds --universal --date="${last_postgres}"
  SUCCESS=YES
  my_date=$( date -Iseconds --universal --date="${last_postgres}" ) || {
    echo "Invalid date format: ${last_postgres}"
    echo "You may want to experiment with running:"
    echo "    date -Iseconds --date='your date and time string here'"
    exit 1
  }
  # Change
  #   2019-05-03T20:10:23+00:00
  # to
  #   2019-05-03\ 20:10:23\ GMT
  my_date=$( echo "${my_date}" | sed 's/T/ /; s/[^-+:0-9]/\\&/g; s/\([0-9]\)\([-+]..:..$\)/\1\\ GMT/' )
  last_postgres="-D ${my_date}"
fi
PGDATA=${PGDATA:?} # typically '/var/lib/postgresql/data'

echo "EXPORT_DIR         = ${EXPORT_DIR:?}"
echo "HOST_EXPORT_DIR    = ${HOST_EXPORT_DIR:?}"
echo "PGDATA             = ${PGDATA}"
echo "PGDATA_PARENT      = ${PGDATA_PARENT:?}"
echo "PGDATA_SUBDIR      = ${PGDATA_SUBDIR:?}"
echo "HOST_PGDATA_PARENT = ${HOST_PGDATA_PARENT:?}"
echo "TAG_POSTGRES       = ${TAG_POSTGRES:?}"
echo "IMAGE_POSTGRES     = ${IMAGE_POSTGRES:?}"
echo "last_postgres      = ${last_postgres}"

PG_RUN="-v ${HOST_PGDATA_PARENT}/${PGDATA_SUBDIR}/:${PGDATA} -v ${HOST_EXPORT_DIR}:/export --rm ${IMAGE_POSTGRES}:${TAG_POSTGRES}"

set -x
set -e

# As root, make sure that:
#   - the pg      CVS repo  exists with proper permissions
#   - the dumpall directory is empty with proper permissions
docker run -u root ${PG_RUN} bash -c "
  echo PATH1a=\$PATH
  "'PATH=$PATH'"
  echo PATH1b=\$PATH
  set -x
  if [ ! -d ${EXPORT_DIR}/backup/pg ]; then
    echo ERROR Missing required directory ${EXPORT_DIR}/backup/pg
    exit 1
  fi
  chown -R postgres:postgres ${EXPORT_DIR}/backup/pg
  if [ -d ${EXPORT_DIR}/dumpall ]; then
    rm -rf ${EXPORT_DIR}/dumpall
  fi
  mkdir ${EXPORT_DIR}/dumpall
  chown -R postgres:postgres ${EXPORT_DIR}/dumpall
"

# As postgres:
#   - check out the version of pg_dumpall.sql appropriate to the supplied date (if any)
docker run -u postgres ${PG_RUN} bash -c "
  echo PATH2a=\$PATH
  "'PATH=$PATH'"
  echo PATH2b=\$PATH
  cd ${PGDATA}
  set -e
  ls -lR ${EXPORT_DIR}/dumpall
  ${EXPORT_DIR}/support/cvs -d ${EXPORT_DIR}/backup/pg co -d ${EXPORT_DIR}/dumpall ${last_postgres} dumpall
"

# do not proceed unless /export/dumpall/pg_dumpall.sql exists!
if [ ! -f ${EXPORT_DIR}/dumpall/pg_dumpall.sql ]; then
  echo "Required file ${EXPORT_DIR}/dumpall/pg_dumpall.sql does not exist!"
  echo "Did you specify a restoration date that was invalid?"
  exit 1
fi
grep pg_dumpall.sql ${EXPORT_DIR}/dumpall/CVS/Entries

# only attempt to backup ${PGDATA_SUBDIR} when ${PGDATA_SUBDIR} exists
OLD_MAIN=""
test -d $PGDATA_PARENT/${PGDATA_SUBDIR}
if [ $# -ne 0 ]; then
  # abort when PostgreSQL appears to be running
  if [ -f $PGDATA_PARENT/${PGDATA_SUBDIR}/postmaster.pid ]; then
    echo "Aborting $0: PostgreSQL database is running."
    exit 1
  fi
  # move ${PGDATA_SUBDIR} to ${PGDATA_SUBDIR}.datetime for safekeeping
  OLD_MAIN=${PGDATA_SUBDIR}.$(date -Iseconds)
  echo now moving $PGDATA_PARENT/${PGDATA_SUBDIR} to $PGDATA_PARENT/${OLD_MAIN}
  mv $PGDATA_PARENT/${PGDATA_SUBDIR} $PGDATA_PARENT/${OLD_MAIN}
fi

# Make an empty ${PGDATA_SUBDIR} directory with the correct permissions
mkdir $PGDATA_PARENT/${PGDATA_SUBDIR}
chown postgres $PGDATA_PARENT/${PGDATA_SUBDIR}

# As postgres, init PostgreSQL db
docker run -u postgres ${PG_RUN} bash -c '
  POSTGRES_PASSWORD=$POSTGRES_PASSWORD
  echo PATH2=$PATH
  initdb -D '"${PGDATA}"'
'

# As postgres:
#   - check out the version of pg_dumpall.sql appropriate to the supplied date (if any)
#   - apply it to the database
docker run -u postgres ${PG_RUN} bash -c "
  echo PATH3a=\$PATH
  "'PATH=$PATH'"
  echo PATH3b=\$PATH
  cd ${PGDATA}
  echo Restore PostgreSQL database at
  pwd
  pg_ctl -D . -l ./logfile start
  set +e
  sleep 5
  echo Restoring PostgreSQL - this may take a while.
  ( (psql < ${EXPORT_DIR}/dumpall/pg_dumpall.sql 2> ./psql_stderr 1> ./psql_stdout) && cp ${EXPORT_DIR}/dumpall/*.conf ${PGDATA} ) || {
    echo PostgreSQL restoration failure
    exit 1
  }
  touch rollbackSuccess
  ls -l ${PGDATA}
  exit 0
"

if [ -d $PGDATA_PARENT/main.fail ]; then
  rm -rf $PGDATA_PARENT/main.fail
fi
test -f $PGDATA/rollbackSuccess
if [ $# -eq 0 ]; then
  rm $PGDATA/rollbackSuccess
  echo Old database preserved at $HOST_PGDATA_PARENT/${OLD_MAIN}
elif [ ! -z "${OLD_MAIN}" ]; then
  mv $PGDATA_PARENT/main $PGDATA_PARENT/main.fail
  mv $PGDATA_PARENT/${OLD_MAIN} $PGDATA_PARENT/main
fi

