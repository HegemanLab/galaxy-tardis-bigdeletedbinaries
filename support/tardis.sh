#!/bin/bash
# tardis.sh - Temporal Archive Remote Distribution and Installation System

#  Note well: Execute this from *outside* a container
usage() {
  echo "tardis - Temporal Archive Remote Distribution and Installation System"
  echo "usage:"
  echo "  rootless bash $0 backup"
  echo "  rootless bash $0 transmit"
  echo "  rootless bash $0 restore"
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
shift # Remove first argument from the argument list

case "$subcommand" in
  backup)
    echo ---
    echo `date --iso-8601=seconds` Backup starting
    echo "Collecting Galaxy configuration"
    docker exec galaxy-init bash -c "ln -s /export/support/cvs /usr/local/bin/cvs; /export/support/config_xml_dump.sh; rm /usr/local/bin/cvs"
    echo "Collecting Galaxy database records"
    docker exec galaxy-postgres /export/support/db_dump.sh
    echo `date --iso-8601=seconds` Backup ended
    echo ...
  ;;
  transmit)
    echo ---
    echo `date --iso-8601=seconds` Transmit starting
    bash $DIR/transmit_backup.sh
    echo `date --iso-8601=seconds` Transmit ended
    echo ...
  ;;
  restore)
    echo ---
    echo `date --iso-8601=seconds` Restore starting
    echo "WARNING 'restore' not yet implemented."
    echo `date --iso-8601=seconds` Restore ended
    echo ...
  ;;
  bash)
    bash
  ;;
  *)
    usage
  ;;
esac


