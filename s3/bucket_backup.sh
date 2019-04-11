#!/bin/bash
if [ $# = 1 -a -e $1 ]; then 
  if [[ "${1:0:1}" = "/" ]]; then
    ABSOLUTE=$1
  else
    ABSOLUTE=$( cd $(dirname $1) && pwd -P)/$(basename $1)
  fi
  s3cmd -c /export/s3/msi_galaxym.s3cfg sync ${ABSOLUTE} s3://msigalaxym-pisces-config${ABSOLUTE}
  s3cmd -c /export/s3/esch0041.s3cfg    sync ${ABSOLUTE} s3://esch0041-pisces-config${ABSOLUTE}
else
  echo usage: bucket_backup.sh path_to_a_file
fi
