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

my_invoke="$0"
my_name="$1"
my_infix="$2"
my_parms="$@"

usage() {
  echo '******************************************************************************'
  echo "Usage: ${my_invoke} path_to_a_file [subdir of ${EXPORT_ROOT}, default is 'restore']"
  echo "This invocation: ${my_invoke} ${my_parms}"
  echo '******************************************************************************'
}
if [ -z "$my_name" ]; then
  usage
  exit 1
fi

# if file or directory does not exit, make sure we can create it
if [ "${my_name: -1:1}" == "/" ]; then
  if [ ! -d ${my_name} ]; then
    mkdir -p ${my_name}
  fi
else
  my_base=$( dirname ${my_name} )
  if [ ! -d ${my_base} ]; then
    mkdir -p ${my_base}
  fi
  if [ ! -f ${my_name} ]; then
    touch ${my_name}
  fi
fi

if [ $# -le 3 -a -e ${my_name} ]; then
  if [[ "${my_name:0:1}" = "/" ]]; then
    ABSOLUTE=${my_name}
  else
    ABSOLUTE=$( cd $(dirname ${my_name}) && pwd -P)/$(basename ${my_name})
  fi
  INFIX="/restore"
  if [ ! -z "${my_infix}" ]; then
    INFIX="/${my_infix}"
  fi
  if [ ! -d ${EXPORT_ROOT}/${INFIX} ]; then
    mkdir -p ${EXPORT_ROOT}/${INFIX}
  fi
  set -x
  s3cmd --no-mime-magic -c ${DIR}/dest.s3cfg sync s3://${CONFIG_BUCKET}${ABSOLUTE} ${EXPORT_ROOT}${INFIX}${ABSOLUTE}
  set +x
else
  usage
  exit 1
fi
