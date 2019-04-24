#!/bin/bash
set -e # abort on error
set -x # verbose

# NOTE WELL - This script ASSUMES that it is located in export/support and that export/backup exists.
EXPORT_ROOT='/export'

# set the actual script directory per https://stackoverflow.com/a/246128
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
cd $DIR/..
OPT_ROOT=`pwd`
# now we should be in the export directory

echo ---
echo `date -I'seconds'` Retrieval starting

# save the files used to copy data and config to the bucket (outside of Galaxy)
# $OPT_ROOT/s3/bucket_retrieve.sh $OPT_ROOT/s3/
# $OPT_ROOT/s3/bucket_retrieve.sh $OPT_ROOT/support/
$OPT_ROOT/s3/bucket_retrieve.sh $EXPORT_ROOT/backup/

# save Galaxy config files necessary to restore the UI
# for f in $EXPORT_ROOT/galaxy-central/config/*.[xy]ml; do 
#   $OPT_ROOT/s3/bucket_retrieve.sh $f
# done
$OPT_ROOT/s3/bucket_retrieve.sh $EXPORT_ROOT/galaxy-central/config/


# # restore the tools and shed_tools
# $OPT_ROOT/s3/bucket_retrieve.sh $EXPORT_ROOT/galaxy-central/tools.yaml
# $OPT_ROOT/s3/bucket_retrieve.sh $EXPORT_ROOT/shed_tools/

echo `date -I'seconds'` Retrieval finishing
echo ...

# BACKUP_LOG=$EXPORT_ROOT/var/log/run_backup.log
# if [ -f $BACKUP_LOG ]; then
#   $OPT_ROOT/s3/bucket_backup.sh $BACKUP_LOG
# fi
