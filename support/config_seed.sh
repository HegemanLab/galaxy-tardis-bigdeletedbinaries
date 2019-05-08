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

set -x

# As root, make sure that:
#   - the config      CVS repo  exists with proper permissions
set -x
if [ ! -d ${EXPORT_DIR}/backup/config ]; then
  echo ERROR Missing required directory ${EXPORT_DIR}/backup/config
  exit 1
fi
chown -R galaxy:galaxy ${EXPORT_DIR}/backup/config

if [ -d ${EXPORT_DIR}/config/CVS ]; then
  rm -rf ${EXPORT_DIR}/config/CVS
fi
su -c "
  set -x
  whoami
  cd ${EXPORT_DIR}/config
  cvs -d ${EXPORT_DIR}/backup/config co -d . ${last_config} config | grep -v '^[?] '
" galaxy

su -c "
  cd ${EXPORT_DIR}/config
  cvs -d ${EXPORT_DIR}/backup/config update -C | grep -v '^[?] '
" galaxy
# cvs -d ${EXPORT_DIR}/backup/config update 2>/dev/null | sed -n '/^C /{s/^C //;p}' | xargs rm 2>/dev/null

# As root, make sure that:
#   - the pgadmin      CVS repo  exists with proper permissions
if [ ! -d ${EXPORT_DIR}/backup/pgadmin ]; then
  echo ERROR Missing optional directory ${EXPORT_DIR}/backup/pgadmin
  exit 0
fi

chgrp -R galaxy ${EXPORT_DIR}/pgadmin
chmod -R g+w  ${EXPORT_DIR}/pgadmin
if [ -d ${EXPORT_DIR}/pgadmin/CVS ]; then
  rm -rf ${EXPORT_DIR}/pgadmin/CVS
fi
su -c "
  set -x
  cd ${EXPORT_DIR}/pgadmin
  cvs -d ${EXPORT_DIR}/backup/pgadmin co -d . ${last_pgadmin} pgadmin | grep -v '^[?] '
" galaxy

su -c "
  cd ${EXPORT_DIR}/pgadmin
  cvs -d ${EXPORT_DIR}/backup/pgadmin update -C | grep -v '^[?] '
" galaxy
# cvs -d ${EXPORT_DIR}/backup/pgadmin update 2>/dev/null | sed -n '/^C /{s/^C //;p}' | xargs rm 2>/dev/null

chown -R 1000 ${EXPORT_DIR}/pgadmin
chmod -R g+w  ${EXPORT_DIR}/pgadmin
