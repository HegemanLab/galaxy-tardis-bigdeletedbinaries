#!/bin/bash

# arg 1, required - file to backup
# arg 2, optional - prefix added to absolute path in bucket (root subdirectory path in bucket)
# arg 3, optional - suffix added for object store, typically some portion of the current date and time
# NOTE WELL - This script ASSUMES that it is located in export/s3

# set the actual script directory per https://stackoverflow.com/a/246128
SOURCE="${BASH_SOURCE[0]}"
while [ -h "${SOURCE}" ]; do # resolve ${SOURCE} until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "${SOURCE}" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "${SOURCE}")"
  [[ ${SOURCE} != /* ]] && SOURCE="${DIR}/${SOURCE}" # if ${SOURCE} was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "${SOURCE}" )" >/dev/null 2>&1 && pwd )"

ABSOLUTE=$1
if [ ! -e ${ABSOLUTE} ]; then
  echo "Warning: ${ABSOLUTE} not found."
  exit 0
fi

# set CONFIG_BUCKET
source ${DIR}/dest.config

if [ $# -le 3 -a -e $1 ]; then
  if [[ "${1:0:1}" = "/" ]]; then
    ABSOLUTE=$1
  else
    ABSOLUTE=$( cd $(dirname $1) && pwd -P)/$(basename $1)
  fi
  PREFIX=""
  if [ ! -z "$2" ]; then
    PREFIX="/$2"
  fi
  SUFFIX=""
  if [ ! -z "$3" ]; then
    SUFFIX="-$3"
  fi
  s3cmd --no-mime-magic -c ${DIR}/dest.s3cfg sync ${ABSOLUTE} s3://${CONFIG_BUCKET}${PREFIX}${ABSOLUTE}${SUFFIX}
else
  echo 'usage: bucket_backup.sh path_to_a_file [suffix]'
  echo "   the args supplied were: $@"
fi
