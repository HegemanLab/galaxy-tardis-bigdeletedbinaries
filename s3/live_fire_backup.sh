#!/bin/bash
pushd /export/galaxy-central/database/files
for f in `find . -type d -print | sed -e 's/..//; /^tmp/ d; 1 d'` ; do 
  echo Syncing files directory $f
  s3cmd -c /export/s3/msi_galaxym.s3cfg sync $f/ s3://msigalaxym-piscesw/$f/
done
