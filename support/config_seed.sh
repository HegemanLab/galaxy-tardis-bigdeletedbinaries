#!/bin/bash
echo "$0 - seed or roll back the Galaxy config directory"

last_config="$1"
echo '$1='"$1"
if [ ! -z "${last_config}"  ]; then
  date -Iseconds --universal --date="${last_config}"
  SUCCESS=YES
  my_date=$( date -Iseconds --universal --date="${last_config}" ) || {
    echo "Invalid date format: ${last_config}"
    echo "You may want to experiment with running:"
    echo "    date -Iseconds --date='your date and time string here'"
    exit 1
  }
  # Change
  #   2019-05-03T20:10:23+00:00
  # to
  #   2019-05-03\ 20:10:23\ GMT
  my_date=$( echo "${my_date}" | sed 's/T/ /; s/[^-+:0-9]/\\&/g; s/\([0-9]\)\([-+]..:..$\)/\1\\ GMT/' )
  last_config="-D ${my_date}"
fi

echo "EXPORT_DIR  = ${EXPORT_DIR:?}"
echo "last_config = ${last_config}"

# As root, make sure that:
#   - the config      CVS repo  exists with proper permissions
if [ ! -d ${EXPORT_DIR}/backup/config ]; then
  echo ERROR Missing required directory ${EXPORT_DIR}/backup/config
  exit 1
fi
chown -R galaxy:galaxy ${EXPORT_DIR}/backup/config

if [ -d ${EXPORT_DIR}/config/CVS ]; then
  rm -rf ${EXPORT_DIR}/config/CVS
fi
su -c "
  whoami
  cd ${EXPORT_DIR}/config
  cvs -d ${EXPORT_DIR}/backup/config co -d . ${last_config} config | grep -v '^[?] '
" galaxy

su -c "
  cd ${EXPORT_DIR}/config
  cvs -d ${EXPORT_DIR}/backup/config update 2>/dev/null | sed -n '/^C /{s/^C //;p}' | xargs rm 2>/dev/null
  cvs -d ${EXPORT_DIR}/backup/config update -C | grep -v '^[?] '
" galaxy

# As root, make sure that:
#   - the pgadmin      CVS repo  exists with proper permissions
if [ ! -d ${EXPORT_DIR}/backup/pgadmin ]; then
  echo ERROR Missing optional directory ${EXPORT_DIR}/backup/pgadmin
else
  chgrp -R galaxy ${EXPORT_DIR}/pgadmin
  chmod -R g+w  ${EXPORT_DIR}/pgadmin
  if [ -d ${EXPORT_DIR}/pgadmin/CVS ]; then
    rm -rf ${EXPORT_DIR}/pgadmin/CVS
  fi
  su -c "
    cd ${EXPORT_DIR}/pgadmin
    cvs -d ${EXPORT_DIR}/backup/pgadmin co -d . ${last_config} pgadmin | grep -v '^[?] '
  " galaxy

  su -c "
    cd ${EXPORT_DIR}/pgadmin
    cvs -d ${EXPORT_DIR}/backup/pgadmin update 2>/dev/null | sed -n '/^C /{s/^C //;p}' | xargs rm 2>/dev/null
    cvs -d ${EXPORT_DIR}/backup/pgadmin update -C | grep -v '^[?] '
  " galaxy

  chown -R 1000 ${EXPORT_DIR}/pgadmin
  chmod -R g+w  ${EXPORT_DIR}/pgadmin
fi

# As root, make sure that:
#   - the conda      CVS repo  exists with proper permissions
rm -rf ${EXPORT_DIR}/restore/conda
mkdir -p ${EXPORT_DIR}/restore/conda
chown -R galaxy:galaxy ${EXPORT_DIR}/restore/conda
chmod -R g+w  ${EXPORT_DIR}/restore/conda
cp /opt/support/cvs /export/support/cvs
# Populate the sandbox, then, for each non-existing environment, reconstitute it
#   Note that no attmept is made to restore the base environment
SUBCOMMAND="
  cd ${EXPORT_DIR}/restore/conda
  /export/support/cvs -d ${EXPORT_DIR}/backup/conda co -d . ${last_config} conda | grep -v '^[?] '
  source ${EXPORT_DIR}/tool_deps/_conda/bin/activate
  for f in *.yml; do
    b=\`echo \$(basename \$f) | sed -e 's/.yml\$//'\`
    if [ \"\$b\" != \"base.yml\" ]; then
      if [ ! -d ${EXPORT_DIR}/tool_deps/_conda/envs/\$b ]; then
        conda env create -f \$b.yml
      else
        echo Conda environment \$b already exists
      fi
    fi
  done
  conda deactivate
"
set +x
docker exec -ti -u galaxy galaxy-web bash -c "$SUBCOMMAND"
