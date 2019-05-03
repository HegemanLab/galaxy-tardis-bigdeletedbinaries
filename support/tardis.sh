#!/bin/bash
# tardis.sh - Temporal Archive Remote Distribution and Installation System

#  Note well: Execute this from *outside* a container
usage() {
  echo "tardis - Temporal Archive Remote Distribution and Installation System"
  echo "usage:"
  echo "  tardis backup"
  echo "  tardis transmit"
  echo "  tardis retrieve_config"
  echo "  tardis restore_files"
  echo "  tardis seed_database [date, optional]"
  echo "  tardis purge_empty_tmp_dirs"
  echo "  tardis bash, if applicable"
}
if [ $# -lt 1 ]; then
  usage
  exit 0
fi

# set the actual script directory per https://stackoverflow.com/a/246128
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

subcommand=$1
subarg=$2

case "$subcommand" in
  backup)
    echo ---
    echo `date -I'seconds'` Backup starting
    echo "Collecting Galaxy configuration"
    if [ ! -d /export/var/log ]; then
      mkdir -p /export/var/log
    fi
    docker cp /opt/support/ galaxy-init:/export/; exit_code="$?"
    if [ "$exit_code" != 0 ]; then
      echo "$0 $1 could not copy files - is galaxy-init running?"
      exit 1
    fi
    docker exec galaxy-init bash -c "/export/support/config_xml_dump.sh" | tee -a /export/var/log/run_backup.log
    echo "Collecting Galaxy database records"
    docker cp /opt/support/ galaxy-postgres:/export/; exit_code="$?"
    if [ "$exit_code" != 0 ]; then
      echo "$0 $1 could not copy files - is galaxy-postgres running?"
      exit 1
    fi
    docker exec galaxy-postgres bash -c "/export/support/db_dump.sh" | tee -a /export/var/log/run_backup.log
    echo `date -I'seconds'` Backup ended
    echo ...
    exit 0
    ;;
  transmit)
    echo ---
    echo `date -I'seconds'` Transmit starting
    if [ ! -d /export/var/log ]; then
      mkdir -p /export/var/log
    fi
    ( bash $DIR/transmit_backup.sh; 
      exit_code="$?";
      if [ "$exit_code" != 0 ]; then
        echo "$0 $1 could transmit files while running transmit_backup.sh"
        exit 1
      fi
    ) | tee -a /export/var/log/run_backup.log
    ( bash $DIR/../s3/live_file_backup.sh; 
      exit_code="$?";
      if [ "$exit_code" != 0 ]; then
        echo "$0 $1 could transmit files while running transmit_backup.sh"
        exit 1
      fi
    ) | tee -a /export/var/log/run_backup.log
    echo `date -I'seconds'` Transmit ended
    echo ...
    exit 0
    ;;
  retrieve_config)
    echo ---
    echo `date -I'seconds'` Retrieve config starting
    bash $DIR/retrieve_backup.sh restore || exit 1
    echo `date -I'seconds'` Retrieve config ended
    echo ...
    exit 0
    ;;
  restore_files)
    echo ---
    echo `date -I'seconds'` Restore files starting
    chown galaxy:galaxy /export/database/files
    su -c "bash $DIR/../s3/live_file_restore.sh || exit 1" galaxy
    echo `date -I'seconds'` Restore files ended
    echo ...
    exit 0
    ;;
  seed_database)
    echo ---
    echo "`date -I'seconds'` Database-seed starting"
    echo "Collecting Galaxy configuration"
    echo "/opt/support/db_seed.sh '${subarg}'"
    /opt/support/db_seed.sh "${subarg}"
    echo "`date -I'seconds'` Database-seed ended"
    echo ...
    exit 0
    ;;
  purge_empty_tmp_dirs)
    echo ---
    echo `date -I'seconds'` "Purge empty tmp dirs starting"
    find /export/galaxy-central/database/files/ -maxdepth 1 -type d -name 'tmp*' -exec rmdir {} \;
    echo `date -I'seconds'` "Purge empty tmp dirs ended"
    echo ...
    exit 0
    ;;
  bash)
    bash
    exit $?
    ;;
  *)
    usage
    exit 1
    ;;
esac


