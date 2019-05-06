#!/bin/bash
set -e
set -x
export CVS=${EXPORT_DIR:?}/support/cvs

# ensure that path ${EXPORT_DIR}/backup/config exists and is owned by galaxy
if [ ! -d ${EXPORT_DIR}/backup ]; then
  mkdir -p ${EXPORT_DIR}/backup
  chown galaxy:galaxy ${EXPORT_DIR}/backup
fi

# ensure that path ${EXPORT_DIR}/backup/config exists and is owned by galaxy
if [ ! -d ${EXPORT_DIR}/backup/config ]; then
  mkdir -p ${EXPORT_DIR}/backup/config
  chown galaxy:galaxy ${EXPORT_DIR}/backup/config
fi

# init CVS repository at ${EXPORT_DIR}/backup/config, owned by galaxy
if [ ! -d ${EXPORT_DIR}/backup/config/CVSROOT ]; then su -l -c "
  ${CVS} -d ${EXPORT_DIR}/backup/config init
" galaxy; fi

# create a `config` module
if [ ! -d ${EXPORT_DIR}/backup/config/config ]; then su -l -c "
  mkdir ${EXPORT_DIR}/backup/config/config
" galaxy; fi

# initialize `config` sandbox if necessary
if [ ! -d ${EXPORT_DIR}/config/CVS ]; then su -l -c "
  cd ${EXPORT_DIR}/config
  ${CVS} -d ${EXPORT_DIR}/backup/config co -d . config > /dev/null
" galaxy; fi

# add files - Note the blend of single and double quotes for deferred
#             and immediate variable substitution, respectively
# commit files and show results
su -l -c "
  cd ${EXPORT_DIR}/config
  for f in *.xml *.yml; do
    "'( grep "[/]$f[/]" CVS/Entries > /dev/null )'" || ${CVS} "'add $f'"
  done
  ${CVS} commit -m 'commit of config files for backup - $(date)'
  ${CVS} update
" galaxy
