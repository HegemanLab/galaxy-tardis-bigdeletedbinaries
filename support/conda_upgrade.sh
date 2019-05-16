#!/bin/bash
echo "$0 - Update conda version"
my_script="$0"
miniconda_url_or_path="$1"
miniconda_hash="$2"
miniconda_staging_path="$3"
STAGED_MINICONDA_INSTALLER=${miniconda_staging_path:-/export/miniconda.sh}
DELETE_STAGED_INSTALLER=yes
usage() {
  echo "
  usage:  $my_script  path_or_name_of_miniconda_installer  md5sum_of_miniconda_installer [optional staging_path_for_miniconda.h]
   e.g.:  $my_script  https://repo.continuum.io/miniconda/Miniconda2-4.6.14-Linux-x86_64.sh  faa7cb0b0c8986ac3cacdbbd00fe4168
   N.B.:  - The MD5 hash is mandatory.  
          - The staging path is optional as an alternative to the default path, ${STAGED_MINICONDA_INSTALLER}
          - The miniconda installer will be executed by bash, so be sure that you trust it and have retrieved it securely.
  "
}

if [ -z "${miniconda_hash}"  ]; then usage; exit 0; fi

echo 'URL_or_path='"${miniconda_url_or_path}" 'md5sum='"${miniconda_hash}"
if [ -f "${miniconda_url_or_path}" ]; then
  if [ "${miniconda_url_or_path}" != "${STAGED_MINICONDA_INSTALLER}" ]; then
    cp   "${miniconda_url_or_path}" ${STAGED_MINICONDA_INSTALLER}
  else
    DELETE_STAGED_INSTALLER=no
  fi
else
  wget --quiet "${miniconda_url_or_path}" -O ${STAGED_MINICONDA_INSTALLER}
fi
if [ ! -f ${STAGED_MINICONDA_INSTALLER}  ]; then
  echo "${miniconda_url_or_path}  -  File not found."
  usage
  exit 0
fi
actual_hash=$(md5sum ${STAGED_MINICONDA_INSTALLER} | sed -e 's/ .*$//')
set -x
if [ "${miniconda_hash}" != "${actual_hash}"  ]; then
  echo "${miniconda_url_or_path}  -  Hash ${actual_hash} differs from expected ${miniconda_hash}."
  usage
  exit 0
fi
set +x

# Upgrade (or install) conda to the export directory
SUBCOMMAND="
  /bin/bash ${STAGED_MINICONDA_INSTALLER} -u -b -p ${EXPORT_DIR:?}/tool_deps/_conda/
"

GALAXY_RUNNING=false
docker ps | grep ${CONTAINER_GALAXY_INIT:?} && GALAXY_RUNNING=true
if [ GALAXY_RUNNING == true ]; then
  docker exec -ti -u galaxy ${CONTAINER_GALAXY_INIT:?} bash -c "$SUBCOMMAND"
else
  docker run --rm -ti -u galaxy --name apply-config -v ${HOST_EXPORT_DIR:?}:/export ${IMAGE_GALAXY_INIT:?}:${TAG_GALAXY:?} bash -c "$SUBCOMMAND"
fi

if [ "${DELETE_STAGED_INSTALLER}" == "yes" ]; then
  rm ${STAGED_MINICONDA_INSTALLER}
fi
