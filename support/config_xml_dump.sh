#!/bin/bash
set -e

# ensure that path /export/backup/config exists and is owned by galaxy
if [ ! -d /export/backup ]; then mkdir /export/backup; fi
if [ ! -d /export/backup/config ]; then mkdir /export/backup/config; fi
cd /export/backup/config
chown galaxy .

# init CVS repository at /export/backup/config, owned by galaxy
if [ ! -d CVSROOT ]; then su -l -c '
  cvs -d /export/backup/config init
' galaxy; fi

if [ ! -d config ]; then su -l -c '
  mkdir /export/backup/config/config
' galaxy; fi

# initialize sandbox if necessary
if [ ! -d /export/galaxy-central/config/CVS ]; then su -l -c '
  cd /export/galaxy-central/config
  cvs -d /export/backup/config co -d . config
' galaxy; fi

# add files
su -l -c '
  cd /export/galaxy-central/config
  cvs add *.xml
  cvs commit -m "commit of config files for backup - $(date)"
' galaxy
