#!/bin/bash

#set -x

# set the actual script directory per https://stackoverflow.com/a/246128
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

touch $STOPPING

# get NET_REMOVE environment variable
source env-for-compose-to-source.sh

echo shut down galaxy web first - it holds open postgres sessions
docker-compose stop galaxy-web

echo giving postgres five seconds to settle down
docker exec -ti galaxy-postgres kill -TERM 1
sleep 5

echo compose_stop: shutting down the galaxy-compose suite
docker-compose down --remove-orphans
#rootlessctl.sh list-ports | sed -n -e '/8080/{ s/[^0-9].*//; p }' | xargs rootlessctl.sh remove-ports
${ROOTLESSCTL_SH_DIR}/rootlessctl.sh list-ports | sed -n -e "$NET_REMOVE" | xargs ${ROOTLESSCTL_SH_DIR}/rootlessctl.sh remove-ports
