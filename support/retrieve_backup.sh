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

# retrieve the CVS repositories
$OPT_ROOT/s3/bucket_retrieve.sh $EXPORT_ROOT/backup/ restore
chown -R galaxy:galaxy $EXPORT_ROOT/restore/export/backup/config
chown -R postgres $EXPORT_ROOT/restore/export/backup/pg

# save Galaxy config files necessary to restore the UI
$OPT_ROOT/s3/bucket_retrieve.sh $EXPORT_ROOT/galaxy-central/config/ restore

# save files necessary to run the installed shed tools
$OPT_ROOT/s3/bucket_retrieve.sh $EXPORT_ROOT/shed_tools/

echo `date -I'seconds'` Retrieval finishing
echo ...
