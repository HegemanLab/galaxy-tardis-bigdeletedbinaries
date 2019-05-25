#!/bin/bash
usage() {
  echo "Usage:"
  echo "  $0 [two-digit-hours-after-midnight-UTC,optional]"
  echo "For example:"
  echo "  $0      # Backup and transmit at 01 hours UTC"
  echo "  $0 06   # Backup and transmit at 06 hours UTC"
}

# Set the actual script directory per https://stackoverflow.com/a/246128
SOURCE="${BASH_SOURCE[0]}"
while [[ -h "$SOURCE" ]]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  # if $SOURCE was a relative symlink, we need to resolve it 
  #    relative to the path where the symlink file was located
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

cd $DIR/tardis
. tardis_envar.sh

NOSUB=true
echo "$1" | grep -E '(^[01][0-9]$)|(^2[0-3]$)' && NOHOUR=false
if [[ "NOHOUR_$NOHOUR" ==  "NOHOUR_false" ]]; then
  $TARDIS cron "$1"
elif [[ -z "$1" ]]; then
  $TARDIS cron
else
  usage
  popd
  exit 1
fi

exit 0
