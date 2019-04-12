#!/bin/bash
# tardis.sh - Temporal Archive Remote Distribution and Installation System

#  Note well: Execute this from *outside* a container
usage() {
  echo "tardis - Temporal Archive Remote Distribution and Installation System"
  echo "usage:"
  echo "  bash $0 backup"
  echo "  bash $0 transmit"
  echo "  bash $0 restore"
}
if [ $# -lt 1 ]; then
  usage
  exit 0
fi

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
    echo "WARNING 'transmit' not yet implemented."
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
  *)
    usage
  ;;
esac


