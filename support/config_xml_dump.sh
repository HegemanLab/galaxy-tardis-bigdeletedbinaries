#!/bin/bash
# This script runs as root on galaxy-init

set -e
export CVS=${EXPORT_DIR:?}/support/cvs

WIPE_CONFIG=no
# Ensure that path ${EXPORT_DIR}/backup exists and is owned by galaxy
if [ ! -d ${EXPORT_DIR}/backup ]; then
  mkdir -p ${EXPORT_DIR}/backup
  chown galaxy:galaxy ${EXPORT_DIR}/backup
  WIPE_CONFIG=yes
fi

# Ensure that path ${EXPORT_DIR}/backup/config exists and is owned by galaxy
if [ ! -d ${EXPORT_DIR}/backup/config ]; then
  WIPE_CONFIG=yes
  mkdir -p ${EXPORT_DIR}/backup/config
  chown galaxy:galaxy ${EXPORT_DIR}/backup/config
fi
if [ $WIPE_CONFIG == yes ]; then
  pushd ${EXPORT_DIR}/config
  find . -type d -name 'CVS' -print | xargs rm -rf
  popd
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

IS_CONDA_MODERN_BASE64=$(echo "
  conda -V
  is_conda_modern=\`conda -V | sed -e '"'s/conda //; s/\([0-9]*\)[.]\([0-9]*\)[.].*$/ \1 -gt 4 -o \1 -eq 4 -a \2 -ge 6 /'"'\`
  if [ "'$is_conda_modern'" ]; then
    CONDA_ACTIVATE='conda activate'
    CONDA_DEACTIVATE='conda deactivate'
    CONDA_FINAL_DEACTIVATE='conda deactivate'
  else
    CONDA_ACTIVATE='source activate'
    CONDA_DEACTIVATE='source deactivate'
    CONDA_FINAL_DEACTIVATE=''
  fi
" | base64 -w 0)
IS_CONDA_MODERN='$(echo "'$IS_CONDA_MODERN_BASE64'" | base64 -d)'

# Add files (cvs add)
# Commit files (cvs commit)
# Show results (cvs update)
SUBCOMMAND="
  echo entering subcommand
  cd ${EXPORT_DIR}/restore/conda
  echo PATH="'\$PATH'"
  source ${EXPORT_DIR}/tool_deps/_conda/bin/activate
  echo PATH="'\$PATH'"
  ${IS_CONDA_MODERN}
  conda env export > base.yml
  "'\${CONDA_DEACTIVATE}'"
  echo PATH="'\$PATH'"
  for d in ${EXPORT_DIR}/tool_deps/_conda/envs/*; do
    dname="'\$(basename \${d})'"
    source ${EXPORT_DIR}/tool_deps/_conda/bin/activate
    "'\${CONDA_ACTIVATE} \${dname}'"
    echo PATH="'\$PATH'"
    conda env export > "'\${dname}.yml'"
    "'\${CONDA_DEACTIVATE}'"
    "'\${CONDA_FINAL_DEACTIVATE}'"
    echo PATH="'\$PATH'"
    ${CVS} add "'\${dname}.yml'"
  done
  ${CVS} commit -m commit_conda_files
  ${CVS} update
  echo leaving subcommand
"
### echo "SUBCOMMAND='
### $SUBCOMMAND
### '"
bash -c "su -c 'bash -c \"$SUBCOMMAND\"' galaxy"
