#!/bin/bash
set -e
export CVS=/export/support/cvs
ls -l /export

# ensure that path /export/backup/config exists and is owned by galaxy
if [ ! -d /export/backup/config ]; then
  mkdir -p /export/backup/config
  chown galaxy:galaxy /export/backup/config
fi

# init CVS repository at /export/backup/config, owned by galaxy
cd /export/backup/config
if [ ! -d CVSROOT ]; then su -l -c "
  $CVS -d /export/backup/config init
" galaxy; fi

if [ ! -d config ]; then su -l -c '
  mkdir /export/backup/config/config
' galaxy; fi

# initialize sandbox if necessary
if [ ! -d /export/galaxy-central/config/CVS ]; then su -l -c "
  cd /export/galaxy-central/config
  $CVS -d /export/backup/config co -d . config
" galaxy; fi

# add files
su -l -c "
  cd /export/galaxy-central/config
  $CVS add *.xml
  $CVS add *.yml
  $CVS commit -m 'commit of config files for backup - $(date)'
" galaxy
