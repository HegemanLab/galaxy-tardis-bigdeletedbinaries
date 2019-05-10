#!/bin/bash
# This script runs as root on galaxy-init

set -e
set -x
export CVS=${EXPORT_DIR:?}/support/cvs

# Ensure that path ${EXPORT_DIR}/backup exists and is owned by galaxy
if [ ! -d ${EXPORT_DIR}/backup ]; then
  mkdir -p ${EXPORT_DIR}/backup
  chown galaxy:galaxy ${EXPORT_DIR}/backup
fi

# Ensure that path ${EXPORT_DIR}/backup/config exists and is owned by galaxy
if [ ! -d ${EXPORT_DIR}/backup/config ]; then
  mkdir -p ${EXPORT_DIR}/backup/config
  chown galaxy:galaxy ${EXPORT_DIR}/backup/config
fi
# init CVS repository at ${EXPORT_DIR}/backup/config, owned by galaxy
if [ ! -d ${EXPORT_DIR}/backup/config/CVSROOT ]; then su -l -c "
  ${CVS} -d ${EXPORT_DIR}/backup/config init
" galaxy; fi
# Create a config module
if [ ! -d ${EXPORT_DIR}/backup/config/config ]; then su -l -c "
  mkdir ${EXPORT_DIR}/backup/config/config
" galaxy; fi
# Initialize config sandbox if necessary
if [ ! -d ${EXPORT_DIR}/config/CVS ]; then su -l -c "
  cd ${EXPORT_DIR}/config
  ${CVS} -d ${EXPORT_DIR}/backup/config co -d . config > /dev/null
" galaxy; fi
# Add files - Note the blend of single and double quotes for deferred
#             and immediate variable substitution, respectively
# Commit files and show results
su -l -c "
  cd ${EXPORT_DIR}/config
  for f in *.xml *.yml; do
    "'( grep "[/]$f[/]" CVS/Entries > /dev/null )'" || ${CVS} "'add $f'"
  done
  ${CVS} commit -m 'commit of config files for backup - $(date)'
  ${CVS} update
" galaxy

# Ensure that path ${EXPORT_DIR}/backup/conda exists and is owned by galaxy
if [ ! -d ${EXPORT_DIR}/backup/conda ]; then
  mkdir -p ${EXPORT_DIR}/backup/conda
  chown galaxy:galaxy ${EXPORT_DIR}/backup/conda
fi
# Initialize fresh conda sandbox, owned by galaxy
if [ -d ${EXPORT_DIR}/restore/conda ]; then
 rm -rf ${EXPORT_DIR}/restore/conda
fi
mkdir -p ${EXPORT_DIR}/restore/conda
chown galaxy:galaxy ${EXPORT_DIR}/restore/conda
# init CVS repository at ${EXPORT_DIR}/backup/conda, owned by galaxy
if [ ! -d ${EXPORT_DIR}/backup/conda/CVSROOT ]; then su -l -c "
  ${CVS} -d ${EXPORT_DIR}/backup/conda init
  mkdir ${EXPORT_DIR}/backup/conda/conda
" galaxy; fi
# initialize the conda env sandbox
su -l -c "
  cd ${EXPORT_DIR}/restore/conda
  ${CVS} -d ${EXPORT_DIR}/backup/conda co -d . conda > /dev/null
" galaxy

set +x
# Add files (cvs add)
# Commit files (cvs commit)
# Show results (cvs update)
SUBCOMMAND="
  cd ${EXPORT_DIR}/restore/conda;
  source ${EXPORT_DIR}/tool_deps/_conda/bin/activate;
  conda env export > base.yml;
  ${CVS} add base.yml;
  for d in ${EXPORT_DIR}/tool_deps/_conda/envs/*; do
    dname="'\$(basename \$d)'";
    conda activate "'\${dname}'";
    conda env export > "'\${dname}.yml'";
    conda deactivate
    ${CVS} add "'\${dname}.yml'";
  done;
  conda deactivate
  ${CVS} commit -m commit_conda_files;
  ${CVS} update
"
set +x
bash -c "
  su -c '
    bash -c \"
    $SUBCOMMAND
    \"
  ' galaxy
"
