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

echo "EXPORT_DIR         = ${EXPORT_DIR:?}"
echo "last_config      = ${last_config}"

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

# fail if last line of the following su list fails
set -e

su -c "
  cd ${EXPORT_DIR}/config
  cvs -d ${EXPORT_DIR}/backup/config update 2>/dev/null | sed -n '/^C /{s/^C //;p}' | xargs rm 2>/dev/null
  cvs -d ${EXPORT_DIR}/backup/config update | grep -v '^[?] '
" galaxy

# restore HEAD to config if needed
if [ ! -z "${last_config}"  ]; then
  su -c "
    set -x
    whoami
    cd ${EXPORT_DIR}/config
    cvs -d ${EXPORT_DIR}/backup/config co -d . config | grep -v '^[?] '
  " galaxy
fi
