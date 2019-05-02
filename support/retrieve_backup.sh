#!/bin/bash

# arg 1, optional - subpath for restoration; default is "restore"
PREFIX=$1

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

# set up $EXPORT_ROOT/restore/$EXPORT_ROOT if it does not yet exist
if [ ! -d $EXPORT_ROOT/restore/$EXPORT_ROOT ]; then
  mkdir -p $EXPORT_ROOT/restore/$EXPORT_ROOT
fi
chown galaxy:galaxy $EXPORT_ROOT/restore/$EXPORT_ROOT
# set up $EXPORT_ROOT/restore/$EXPORT_ROOT/backup if it does not yet exist
if [ ! -d $EXPORT_ROOT/restore/$EXPORT_ROOT/backup ]; then
  mkdir $EXPORT_ROOT/restore/$EXPORT_ROOT/backup
fi
chown galaxy:galaxy $EXPORT_ROOT/restore/$EXPORT_ROOT/backup
# set up $EXPORT_ROOT/restore/$EXPORT_ROOT/backup/pg if it does not yet exist
if [ ! -d /$EXPORT_ROOT/restore/$EXPORT_ROOT/backup/pg ]; then
  mkdir -p /$EXPORT_ROOT/restore/$EXPORT_ROOT/backup/pg
fi
chown postgres /$EXPORT_ROOT/restore/$EXPORT_ROOT/backup/pg

# retrieve the CVS repositories
su -c "$OPT_ROOT/s3/bucket_retrieve.sh $EXPORT_ROOT/backup/config/ .." galaxy
su -c "$OPT_ROOT/s3/bucket_retrieve.sh $EXPORT_ROOT/backup/pg/ .." postgres

# save Galaxy config files necessary to restore the UI
su -c "
  $OPT_ROOT/s3/bucket_retrieve.sh $EXPORT_ROOT/galaxy-central/config/ restore
  ls -la $EXPORT_ROOT/restore/$EXPORT_ROOT/galaxy-central/config/
" galaxy


# save files necessary to run the installed shed tools
su -c "$OPT_ROOT/s3/bucket_retrieve.sh $EXPORT_ROOT/shed_tools/ .." galaxy

echo `date -I'seconds'` Retrieval finishing
echo ...
