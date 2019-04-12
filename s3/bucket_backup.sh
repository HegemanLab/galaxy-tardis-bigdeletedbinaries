#!/bin/bash

# NOTE WELL - This script ASSUMES that it is located in export/s3

# set the actual script directory per https://stackoverflow.com/a/246128
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
EXPORT_ROOT=$DIR/..
# now we should be in the export directory

if [ $# = 1 -a -e $1 ]; then 
  if [[ "${1:0:1}" = "/" ]]; then
    ABSOLUTE=$1
  else
    ABSOLUTE=$( cd $(dirname $1) && pwd -P)/$(basename $1)
  fi
  s3cmd -c $EXPORT_ROOT/s3/msi_galaxym.s3cfg sync ${ABSOLUTE} s3://msigalaxym-piscesv-test-config${ABSOLUTE}
  s3cmd -c $EXPORT_ROOT/s3/esch0041.s3cfg    sync ${ABSOLUTE} s3://esch0041-piscesv-test-config${ABSOLUTE}
else
  echo usage: bucket_backup.sh path_to_a_file
fi
