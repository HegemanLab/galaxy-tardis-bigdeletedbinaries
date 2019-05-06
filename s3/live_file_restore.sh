#!/bin/bash

# set the actual script directory per https://stackoverflow.com/a/246128
SOURCE="${BASH_SOURCE[0]}"
while [ -h "${SOURCE}" ]; do # resolve ${SOURCE} until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "${SOURCE}" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "${SOURCE}")"
  [[ ${SOURCE} != /* ]] && SOURCE="${DIR}/${SOURCE}" # if ${SOURCE} was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "${SOURCE}" )" >/dev/null 2>&1 && pwd )"

# set FILE_BUCKET
source ${DIR}/dest.config

EXPORT_ROOT=${EXPORT_DIR:?} # typically '/export'

s3cmd --no-mime-magic -c ${DIR}/dest.s3cfg sync s3://${FILE_BUCKET}/ ${EXPORT_ROOT}/galaxy-central/database/files/
