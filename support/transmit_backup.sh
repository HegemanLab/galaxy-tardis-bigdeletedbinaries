#!/bin/bash
set -e
set -x # verbose

# NOTE WELL - This script ASSUMES that it is located in export/support and that export/backup exists.

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

# record a copy of configuration settings passed through environment variables
ENV_BACKUP=$EXPORT_ROOT/backup/galaxy_env.txt
if [ -f $ENV_BACKUP ]; then
  rm $ENV_BACKUP
fi
RUN_LIST=$(docker-compose ps | grep '^[a-zA-Z]' | cut -f 1 -d ' ')
for a in $RUN_LIST; do
  echo '---' >> $ENV_BACKUP
  echo "# environment variables for service $a" >> $ENV_BACKUP
  docker exec $a bash -c "printenv" | sort >> $ENV_BACKUP
  echo '...' >> $ENV_BACKUP
done

# save the files used to copy data and config to the bucket (outside of Galaxy)
$EXPORT_ROOT/s3/bucket_backup.sh $EXPORT_ROOT/s3/
$EXPORT_ROOT/s3/bucket_backup.sh $EXPORT_ROOT/backup/
$EXPORT_ROOT/s3/bucket_backup.sh $EXPORT_ROOT/support/

# save Galaxy config files necessary to restore the UI
$EXPORT_ROOT/s3/bucket_backup.sh $EXPORT_ROOT/galaxy-central/config/object_store_conf.xml
$EXPORT_ROOT/s3/bucket_backup.sh $EXPORT_ROOT/galaxy-central/config/shed_tool_conf.xml
$EXPORT_ROOT/s3/bucket_backup.sh $EXPORT_ROOT/galaxy-central/config/tool_conf.xml
$EXPORT_ROOT/s3/bucket_backup.sh $EXPORT_ROOT/galaxy-central/integrated_tool_panel.xml


# save the tools and shed_tools
$EXPORT_ROOT/s3/bucket_backup.sh $EXPORT_ROOT/galaxy-central/tools.yaml
$EXPORT_ROOT/s3/bucket_backup.sh $EXPORT_ROOT/shed_tools/

echo `date --iso-8601=seconds` Backup finishing
echo ...

BACKUP_LOG=$EXPORT_ROOT/var/log/run_backup.log
if [ -f $BACKUP_LOG ]; then
  $EXPORT_ROOT/s3/bucket_backup.sh $BACKUP_LOG
fi
