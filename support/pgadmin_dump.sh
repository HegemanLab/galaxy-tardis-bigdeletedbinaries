#!/bin/bash
set -e
export CVS=${EXPORT_DIR:?}/support/cvs

# ensure that path ${EXPORT_DIR}/backup/pgadmin exists and is owned by galaxy
if [ ! -d ${EXPORT_DIR}/backup/pgadmin ]; then
  mkdir -p ${EXPORT_DIR}/backup/pgadmin
  chown galaxy:galaxy ${EXPORT_DIR}/backup/pgadmin
  # wipe CVS directories from pgadmin sandbox
  pushd ${EXPORT_DIR}/pgadmin
  find . -type d -name 'CVS' -print | xargs rm -rf
  popd
fi

# init CVS repository at ${EXPORT_DIR}/backup/pgadmin, owned by galaxy
if [ ! -d ${EXPORT_DIR}/backup/pgadmin/CVSROOT ]; then su -l -c "
  ${CVS} -d ${EXPORT_DIR}/backup/pgadmin init
" galaxy; fi

# create a `pgadmin` module
if [ ! -d ${EXPORT_DIR}/backup/pgadmin/pgadmin ]; then su -l -c "
  mkdir ${EXPORT_DIR}/backup/pgadmin/pgadmin
" galaxy; fi

# initialize `pgadmin` sandbox if necessary
chgrp -R galaxy ${EXPORT_DIR}/pgadmin
chmod -R g+rw  ${EXPORT_DIR}/pgadmin
if [ ! -d ${EXPORT_DIR}/pgadmin/CVS ]; then su -l -c "
  cd ${EXPORT_DIR}/pgadmin
  ${CVS} -d ${EXPORT_DIR}/backup/pgadmin co -d . pgadmin > /dev/null
" galaxy; fi

# add files - Note the blend of single and double quotes for deferred
#             and immediate variable substitution, respectively
# commit files and show results
su -l -c "
  cd ${EXPORT_DIR}/pgadmin
  find . -type d -print | grep -v CVS | grep -v '^[.]$' | xargs ${CVS} add
  find . -type f -print | grep -v CVS | xargs ${CVS} add
  ${CVS} commit -m 'commit of pgadmin files for backup - $(date)'
  ${CVS} update
" galaxy
