#!/bin/bash

# arg 1, required - file to backup
# arg 2, optional - subpath for restoration; default is "restore"

# set the actual script directory per https://stackoverflow.com/a/246128
SOURCE="${BASH_SOURCE[0]}"
while [ -h "${SOURCE}" ]; do # resolve ${SOURCE} until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "${SOURCE}" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "${SOURCE}")"
  [[ ${SOURCE} != /* ]] && SOURCE="${DIR}/${SOURCE}" # if ${SOURCE} was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "${SOURCE}" )" >/dev/null 2>&1 && pwd )"

# set EXPORT_ROOT and CONFIG_BUCKET
source ${DIR}/dest.config
# #e.g.:
# FILE_BUCKET=msigalaxym-piscesv-test-w
# CONFIG_BUCKET=msigalaxym-piscesv-test-config
# EXPORT_ROOT=/export

if [ $# -le 2 -a -e $1 ]; then
  if [[ "${1:0:1}" = "/" ]]; then
    ABSOLUTE=$1
  else
    ABSOLUTE=$( cd $(dirname $1) && pwd -P)/$(basename $1)
  fi
  INFIX="/restore"
  if [ ! -z "$2" ]; then
    INFIX="/$2"
  fi
  if [ ! -d ${EXPORT_ROOT}/${INFIX} ]; then
    mkdir -p ${EXPORT_ROOT}/${INFIX}
  fi
  s3cmd --no-mime-magic -c ${DIR}/dest.s3cfg sync s3://${CONFIG_BUCKET}${ABSOLUTE} ${EXPORT_ROOT}${INFIX}${ABSOLUTE}
else
  echo "usage: $0 path_to_a_file [subdir of ${EXPORT_ROOT}, default is 'restore']"
fi
