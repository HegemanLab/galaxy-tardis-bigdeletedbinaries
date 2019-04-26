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

# if [ ! -e /export/support ]; then
#   ln -s /opt/support /export/support
# fi
# if [ ! -e /export/s3 ]; then
#   ln -s /opt/s3 /export/s3
# fi

subcommand=$1
shift # Remove first argument from the argument list

case "$subcommand" in
  backup)
    echo ---
    echo `date -I'seconds'` Backup starting
    echo "Collecting Galaxy configuration"
    docker cp /opt/support/ galaxy-init:/export/
    docker exec galaxy-init bash -c "/export/support/config_xml_dump.sh"
    echo "Collecting Galaxy database records"
    docker cp /opt/support/ galaxy-postgres:/export/
    docker exec galaxy-postgres bash -c "/export/support/db_dump.sh"
    echo `date -I'seconds'` Backup ended
    echo ...
    exit 0
    ;;
  transmit)
    echo ---
    echo `date -I'seconds'` Transmit starting
    bash $DIR/transmit_backup.sh
    bash $DIR/../s3/live_file_backup.sh
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


