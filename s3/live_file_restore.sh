#!/bin/bash

# NOTE WELL - This script ASSUMES that it is located in export/s3

# set the actual script directory per https://stackoverflow.com/a/246128
SOURCE="${BASH_SOURCE[0]}"
while [ -h "${SOURCE}" ]; do # resolve ${SOURCE} until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "${SOURCE}" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "${SOURCE}")"
  [[ ${SOURCE} != /* ]] && SOURCE="${DIR}/${SOURCE}" # if ${SOURCE} was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "${SOURCE}" )" >/dev/null 2>&1 && pwd )"

# set EXPORT_ROOT and FILE_BUCKET
source ${DIR}/dest.config

s3cmd --no-mime-magic -c ${DIR}/dest.s3cfg sync s3://${FILE_BUCKET}/ ${EXPORT_ROOT}/galaxy-central/database/files/
