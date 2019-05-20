#!/bin/bash source this file - do not execute it

# set the actual script directory per https://stackoverflow.com/a/246128
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

source $DIR/tags-for-tardis_envar-to-source.sh
# e.g.:
# EXPORT_DIR='/mnt/ace/piscesv/export'
# INTERNAL_EXPORT_DIR='/export'
# PGDATA_PARENT='/mnt/ace/piscesv/postgres'
# IMAGE_POSTGRES='quay.io/bgruening/galaxy-postgres'
# CONTAINER_POSTGRES='galaxy-postgres'
# TAG_POSTGRES='9.6.5_for_19.01'
# CONTAINER_GALAXY_INIT='quay.io/bgruening/galaxy-init'
# IMAGE_GALAXY_INIT='quay.io/bgruening/galaxy-init'
# TAG_GALAXY='19.01'

# fail if EXPORT_DIR is not specified; to address this failure, e.g., EXPORT_DIR=/full/path/to/export
if [ ! -d ${EXPORT_DIR:?} ]; then
 echo "Please set EXPORT_DIR (which must contain the exported files referenced by galomix-compose) before sourcing ${SOURCE}"
fi

# fail if PGDATA_PARENT is not specified; to address this failure, e.g., EXPORT_DIR=/mnt/ace/piscesv/postgres
if [ ! -d ${PGDATA_PARENT:?} ]; then
 echo "Please set PGDATA_PARENT (which must contain a directory named 'main' containing the PostgreSQL data for galomix-compose) before sourcing ${SOURCE}"
fi

# fail if TAG_POSTGRES is not specified; to address this failure, e.g., TAG_POSTGRES="9.6.5_for_19.01"
if [ -z "${TAG_POSTGRES:?}" ]; then
 echo "Please set TAG_POSTGRES (a valid tag for an image of quay.io/bgruening/galaxy-postgres) before sourcing ${SOURCE}"
fi

if [ ! -f $DIR/s3/dest.s3cfg ]; then
  echo "ERROR: $DIR/s3/dest.s3cfg does not exist or is not a file"
elif [ ! -f $DIR/s3/dest.config ]; then
  echo "ERROR: $DIR/s3/dest.config does not exist or is not a file"
else
  TARDIS="docker run --rm -ti \
    -v ${XDG_RUNTIME_DIR:?}/docker.sock:/var/run/docker.sock \
    -v $DIR/s3/dest.s3cfg:/opt/s3/dest.s3cfg \
    -v $DIR/s3/dest.config:/opt/s3/dest.config \
    -v ${EXPORT_DIR:?}:${INTERNAL_EXPORT_DIR:?} \
    -e EXPORT_DIR=${INTERNAL_EXPORT_DIR:?} \
    -e HOST_EXPORT_DIR=${EXPORT_DIR:?} \
    -v ${PGDATA_PARENT:?}:/pgparent \
    -e PGDATA_PARENT=/pgparent \
    -e HOST_PGDATA_PARENT=${PGDATA_PARENT:?} \
    -e PGDATA_SUBDIR=${PGDATA_SUBDIR:-main} \
    -e TAG_POSTGRES=${TAG_POSTGRES:?} \
    -e IMAGE_POSTGRES=${IMAGE_POSTGRES:?} \
    -e CONTAINER_POSTGRES=${CONTAINER_POSTGRES:?} \
    -e TAG_GALAXY=${TAG_GALAXY:?} \
    -e IMAGE_GALAXY_INIT=${IMAGE_GALAXY_INIT:?} \
    -e CONTAINER_GALAXY_INIT=${CONTAINER_GALAXY_INIT:?} \
    --name tardis tardis"
  echo "TARDIS=$TARDIS"
fi
