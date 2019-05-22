#!/bin/bash

# Shell function definitions
usage() {
  echo "usage: $0               Start suite, initializing database and export-directory as needed."
  echo "       $0 --init-only   Do not run Galaxy after initializing export-directory and perhaps database."
  echo "       $0 --init-db     Initialize PostgreSQL database if needed."
  echo "       $0 --upgrade-db  Upgrade initialized or existing PostgreSQL database to match Galaxy."
}

swab_orphans() {
  # find and destroy exited containers
  for c in $(docker ps -a --filter="status=exited" -q); do
    docker rm $c
  done
  # find and destroy orphaned volumes
  for v in $(docker volume ls -q -f 'dangling=true'); do
    docker volume rm $v
  done
}

# Extract command-line options
INIT_ONLY=false
INIT_DB=false
UPGRADE_DB=false
if [ ! -z "$1" ]; then
  RESTORE_DATABASE=false
  for arg in "$@"; do
    if [ ${arg:0:2} == "--" ]; then
      case "${arg:2}" in
        init-only)
          echo "Initializing Galaxy export without running Galaxy"
          INIT_ONLY=true
          ;;
        init-db)
          echo "Not initializing PostgreSQL database"
          INIT_DB=true
          ;;
        upgrade-db)
          echo "Upgrading PostgreSQL database to match Galaxy version"
          UPGRADE_DB=true
          ;;
        help)
          usage
          exit 0
          ;;
        *)
          echo "Unrecognized option"
          usage
          exit 1
          ;;
      esac
    fi
  done
fi
# Sanity checks
#TODO remove next line
echo INIT_ONLY=$INIT_ONLY INIT_DB=$INIT_DB UPGRADE_DB=$UPGRADE_DB

# Set the actual script directory per https://stackoverflow.com/a/246128
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
pushd $DIR
STOPPING=$DIR/STOPPING

ROOTLESSCTL_SH_DIR="$( cd -P "$( dirname `which rootlesskit` )/.." >/dev/null 2>&1 && pwd )"

TERM_ACTION="$DIR/compose_stop.sh; sleep 2; swab_orphans"
TERM_ACTION="$DIR/compose_stop.sh; sleep 2; swab_orphans; exit 1"
# catch request to stop
trap "echo TERM caught; ${TERM_ACTION}" TERM
# catch control-C
trap "echo INT caught; ${TERM_ACTION}" INT

# Get invariant environment variables for this Galaxy instance
source env-for-compose-to-source.sh

# Get tags produced by build-orchestration-images.sh
source tags-for-compose-to-source.sh

docker-compose -f ${COMPOSE_FILE:?} ps >/dev/null || {
  echo "
    Settings for docker-compose to run '$COMPOSE_FILE' are somehow amiss.
    Please check configuration, e.g.:
      env-for-compose-to-source.sh
      tags-for-compose-to-source.sh
  "
  exit 1
}

docker-compose -f $COMPOSE_FILE ps | grep galaxy-postgres && {
  echo "
    Please do not run $0 without stopping the 'galaxy-postgres' service.
    For example, you could run the compose_stop.sh script before running $0.
  "
  exit 1
}
docker-compose -f $COMPOSE_FILE ps | grep galaxy-postgres || rootlesskit --disable-host-loopback bash -c "
  if [ -f $PGDATA_DIR/postmaster.pid ]; then
    rm $PGDATA_DIR/postmaster.pid
  fi
"
if [ -f $STOPPING ]; then
  rm $STOPPING
fi

docker-compose -f $COMPOSE_FILE run --rm galaxy-init /bin/bash -c "export DISABLE_SLEEPLOCK=yes; /usr/bin/startup"

if [ "INIT_DB_$INIT_DB" == "INIT_DB_true" ]; then
  echo "Initializing database if it does not exist"  # TODO remove
  rootlesskit --disable-host-loopback bash -c "
    if [ -f ${PGDATA_DIR:?}/PG_VERSION ]; then
      echo PG_VERSION found
    else
      echo PG_VERSION not found
    fi
  "
  # Init the db if its directory does not exist or is not initialized
  ( rootlesskit --disable-host-loopback test -f ${PGDATA_DIR:?}/PG_VERSION ) || {

    docker-compose -f $COMPOSE_FILE up -d galaxy-postgres
    echo compose_start: sleeping for four minutes while database populates ...
    sleep 60
    if [ -f $STOPPING ]; then exit 0; fi
    docker-compose -f $COMPOSE_FILE exec galaxy-postgres ps ajxf
    rootlesskit --disable-host-loopback ls $PGDATA_DIR
    echo compose_start: ... sleeping for three minutes while database populates ...
    sleep 60
    if [ -f $STOPPING ]; then exit 0; fi
    docker-compose -f $COMPOSE_FILE exec galaxy-postgres ps ajxf
    rootlesskit --disable-host-loopback ls $PGDATA_DIR
    echo compose_start: ... sleeping for two minutes while database populates ...
    sleep 60
    if [ -f $STOPPING ]; then exit 0; fi
    docker-compose -f $COMPOSE_FILE exec galaxy-postgres ps ajxf
    rootlesskit --disable-host-loopback ls $PGDATA_DIR
    echo compose_start: ... sleeping for one minute while database populates ...
    sleep 60
    docker-compose -f $COMPOSE_FILE exec galaxy-postgres ps ajxf
    rootlesskit --disable-host-loopback ls $PGDATA_DIR
    echo compose_start: stopping the database container in preparation for starting the whole suite
    docker-compose -f $COMPOSE_FILE down --remove-orphans
    swab_orphans
    if [ -f $STOPPING ]; then exit 0; fi
  }
fi

if [ "$UPGRADE_DB" == "true" ]; then
  # set TARDIS environment variable
  source tardis/tardis_envar.sh
  # upgrade database
  echo "***** Database upgrade - begin *****"
  docker-compose -f $COMPOSE_FILE up -d galaxy-postgres galaxy-web
  $TARDIS upgrade_database
  docker-compose -f $COMPOSE_FILE down --remove-orphans
  echo "***** Database upgrade - complete *****"
  # upgrade database end
  swab_orphans
fi

if [ -f $STOPPING ]; then exit 0; fi

if [ "$INIT_ONLY" != "true" ]; then
  echo '######### compose_start: Forwarding ports into namesapce ########'

  echo 'Forward ports into namespace, as specified in env-for-compose-to-source.sh - BEGIN'
  # Forward ports into namespace, as specified in env-for-compose-to-source.sh
  # rootlessctl.sh add-ports 0.0.0.0:8080:8080/tcp
  # export NET_ADD='0.0.0.0:8080:8080/tcp'
  ${ROOTLESSCTL_SH_DIR}/rootlessctl.sh add-ports $NET_ADD
  ${ROOTLESSCTL_SH_DIR}/rootlessctl.sh list-ports
  echo 'Forward ports into namespace, as specified in env-for-compose-to-source.sh - END'

  echo '######### compose_start: Starting the galaxy-compose suite ########'
  # Start the container-services
  # docker-compose up galaxy-postgres galaxy-slurm galaxy-web galaxy-proftpd rabbitmq galaxy-init grafana
  # export CONTAINERS_TO_RUN='galaxy-postgres galaxy-slurm galaxy-web galaxy-proftpd rabbitmq galaxy-init grafana'
  docker-compose -f $COMPOSE_FILE up $CONTAINERS_TO_RUN
  echo $COMPOSE_FILE up interrupted
fi
if [ -f $STOPPING ]; then exit 0; fi
