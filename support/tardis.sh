#!/bin/bash
#  Note well: Execute this from *outside* a container
usage() {
  echo "usage:"
  echo "  bash $0 backup"
  echo "  bash $0 transmit"
  echo "  bash $0 retrieve"
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
    echo "Collecting Galaxy configuration"
    docker exec galaxy-init bash -c "ln -s /export/support/cvs /usr/local/bin/cvs; /export/support/config_xml_dump.sh; rm /usr/local/bin/cvs"
    echo "Collecting Galaxy database records"
    docker exec galaxy-postgres /export/support/db_dump.sh
    echo "Backups completed - ready to transmit"
  ;;
  transmit)
    echo "WARNING 'transmit' not yet implemented."
  ;;
  retrieve)
    echo "WARNING 'retrieve' not yet implemented."
  ;;
  restore)
    echo "WARNING 'restore' not yet implemented."
  ;;
  *)
    usage
  ;;
esac


