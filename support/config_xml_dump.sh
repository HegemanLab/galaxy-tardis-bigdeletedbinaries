#!/bin/bash
set -e
export CVS=/export/support/cvs

# ensure that path /export/backup/config exists and is owned by galaxy
if [ ! -d /export/backup ]; then
  if [ -d /export/restore/export/backup ]; then
    mv /export/restore/export/backup /export/backup
  else
    mkdir -p /export/backup
    chown galaxy:galaxy /export/backup
  fi
fi

# ensure that path /export/backup/config exists and is owned by galaxy
if [ ! -d /export/backup/config ]; then
  if [ -d /export/restore/export/backup/config ]; then
    mv /export/restore/export/backup/config /export/backup/config
  else
    mkdir -p /export/backup/config
    chown galaxy:galaxy /export/backup/config
  fi
fi

# init CVS repository at /export/backup/config, owned by galaxy
if [ ! -d /export/backup/config/CVSROOT ]; then su -l -c "
  $CVS -d /export/backup/config init
" galaxy; fi

# create a `config` module
if [ ! -d /export/backup/config/config ]; then su -l -c '
  mkdir /export/backup/config/config
' galaxy; fi

# initialize `config` sandbox if necessary
if [ ! -d /export/galaxy-central/config/CVS ]; then su -l -c "
  cd /export/galaxy-central/config
  $CVS -d /export/backup/config co -d . config > /dev/null
" galaxy; fi

# add files - Note the blend of single and double quotes for deferred
#             and immediate variable substitution, respectively
# commit files and show results
su -l -c "
  cd /export/galaxy-central/config
  for f in *.xml *.yml; do
    "'( grep "[/]$f[/]" CVS/Entries > /dev/null )'" || $CVS "'add $f'"
  done
  $CVS commit -m 'commit of config files for backup - $(date)'
  $CVS update
" galaxy
