#!/bin/bash
usage() {
  echo "Usage (note that options may be combined):"
  echo "  $0 --help                   Show this help text"
  echo "  $0 --retrieve_config        Retrieve config data"
  echo "  $0 --apply_config ['date']  Apply retrieved config data"
  echo "  $0 --datasets               Restore ALL dataset file (not necessary when using Galaxy object store)"
  echo "  $0 --db_upgrade             Upgrade PostgreSQL to match installed Galaxy version"
  echo "  $0 --database ['date']      Restore PostgreSQL database (this makes database changes since last backup unavailable)"
  echo "        'date' can be used to specify the newest backup can be applied, i.e., exclude backups newer than the date"
  echo "        'date' can be any format accepted by the Linxx 'date' program (https://linux.die.net/man/1/date),"
  echo "            which may be relative (e.g., '3 days ago')"
  echo "            or RFC822  (e.g., '28 Apr 2019 05:20:23 -5')  [where '-5' means five hours behind UTC]"
  echo "            or pseudo ISO8601 ('2019-04-28 05:20:23 -05:00')  [where '-05:00' means five hours behind UTC]."
  echo "            It is quite flexible, so go ahead and try something that makes sense to you."
  echo "  $0 --Miniconda3             Upgrade /export/_conda to the latest Miniconda3 version. (experimental, requires lynx)"
  echo "  $0 --Miniconda2             Upgrade /export/_conda to the latest Miniconda2 version. (experimental, requires lynx)"
}
if [ -z "$1" ]; then
  usage
  exit 1
fi

APPLY_CONFIG=false
RETRIEVE_CONFIG=false
RESTORE_DATASETS=false
RESTORE_DATABASE=false
UPGRADE_DATABASE=false
UPGRADE_MINICONDA3=false
UPGRADE_MINICONDA2=false
last_arg=""
last_postgres=""
for arg in "$@"; do
  echo "arg: ${arg}"
  if [ ${arg:0:2} == "--" ]; then
   case "${arg:2}" in
      Miniconda3)
        echo "  Upgrade /export/_conda to the latest Miniconda3 version. (experimental, requires lynx)"
        UPGRADE_MINICONDA3=true
        ;;
      Miniconda2)
        echo "  Upgrade /export/_conda to the latest Miniconda2 version. (experimental, requires lynx)"
        UPGRADE_MINICONDA2=true
        ;;
      db_upgrade)
        echo "  Restore PostgreSQL database (this makes database changes since last backup unavailable)"
        UPGRADE_DATABASE=true
        ;;
      database)
        echo "  Restore PostgreSQL database (this makes database changes since last backup unavailable)"
        RESTORE_DATABASE=true
        ;;
      datasets)
        echo "  Restore ALL dataset file (not necessary when using Galaxy object store)"
        RESTORE_DATASETS=true
        ;;
      retrieve_config)
        echo "  Retrieve config data"
        RETRIEVE_CONFIG=true
        ;;
      apply_config)
        echo "  Apply retrieved config data"
        APPLY_CONFIG=true
        ;;
      help)
        usage
        exit 0
        ;;
      *)
        echo "Unrecognized option ${arg}"
        usage
        exit 1
        ;;
    esac
  elif [ "${last_arg}" == "--database"  ]; then
    date -Iseconds --date="${arg}"
    my_date=$( date -Iseconds --date="${arg}" ) || {
      echo "Invalid date format: ${arg}"
      echo "You may want to experiment with running:"
      echo "    date -Iseconds --date='your date and time string here'"
      exit 1
    }
    last_postgres="${arg}"
    echo "    Database rollback date to $my_date"
  elif [ "${last_arg}" == "--apply_config"  ]; then
    date -Iseconds --date="${arg}"
    my_date=$( date -Iseconds --date="${arg}" ) || {
      echo "Invalid date format: ${arg}"
      echo "You may want to experiment with running:"
      echo "    date -Iseconds --date='your date and time string here'"
      exit 1
    }
    last_config="${arg}"
    echo "    Configuration rollback date to $my_date"
  else
    echo "Unrecognized option '${arg}'"
    usage
    exit 1
  fi
  last_arg="${arg}"
done

echo "
APPLY_CONFIG=$APPLY_CONFIG
RETRIEVE_CONFIG=$RETRIEVE_CONFIG
RESTORE_DATASETS=$RESTORE_DATASETS
RESTORE_DATABASE=$RESTORE_DATABASE
UPGRADE_DATABASE=$UPGRADE_DATABASE
UPGRADE_MINICONDA3=$UPGRADE_MINICONDA3
UPGRADE_MINICONDA2=$UPGRADE_MINICONDA2
"
# Set the actual script directory per https://stackoverflow.com/a/246128
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
echo "DIR is $DIR"
pushd $DIR

#set -x

# Get invariant environment variables for this Galaxy instance
source env-for-compose-to-source.sh

# Get tags produced by build-orchestration-images.sh
source tags-for-compose-to-source.sh

SAVE_DIR=$DIR
pushd tardis
. tardis_envar.sh
popd # undo `pushd tardis`
DIR=$SAVE_DIR

if [ -z "$TARDIS" ]; then
  echo "FATAL - The TARDIS environment variable was not set; review tardis_envar.sh to see what variables you might need to set."
  exit 1
fi

# set INTERNAL_EXPORT_ROOT to the path to export inside the docker container
echo export $(cat tardis/tags-for-tardis_envar-to-source.sh | sed -n -e '/EXPORT_DIR/ {s/^/INTERNAL_/; p}')
export $(cat tardis/tags-for-tardis_envar-to-source.sh | sed -n -e '/EXPORT_DIR/ {s/^/INTERNAL_/; p}')

echo EXPORT_DIR=$EXPORT_DIR
if [ ! -e $EXPORT_DIR/backup ]; then
  rootlesskit --disable-host-loopback mkdir -p $EXPORT_DIR/backup
fi

# Upgrade /export/_conda to latest Miniconda2 or Miniconda3
if [ "$UPGRADE_MINICONDA3" != "false" -o "$UPGRADE_MINICONDA2" != "false" ]; then
  which lynx || {
    echo '
      Upgrading to latest Miniconda2 or Miniconda3 requires that "lynx" be installed.
      Alternatively, you can visit https://repo.continuum.io/miniconda/ to find what
      you want and then run something like:
        $TARDIS upgrade_conda https://repo.continuum.io/miniconda/Miniconda2-4.6.14-Linux-x86_64.sh  faa7cb0b0c8986ac3cacdbbd00fe4168
    '
    exit 1
  }
  # The following is approximately equivalent to:
  #   lynx -nonumbers -width=160 -dump https://repo.continuum.io/miniconda/ | grep -v https |  grep latest-Linux-x86_64 | sed -e 's/^[ ]*\([^ ]*\).* \([^ ]*\)$/'"$TARDIS"' upgrade_conda \1 \2/'
  #   $TARDIS upgrade_conda https://repo.continuum.io/miniconda/Miniconda2-4.6.14-Linux-x86_64.sh  faa7cb0b0c8986ac3cacdbbd00fe4168
  my_substring=Miniconda2
  if [ "$UPGRADE_MINICONDA3" != "false" ]; then
    my_substring=Miniconda3
  fi
  my_command() {
    lynx -nonumbers -width=160 -dump https://repo.continuum.io/miniconda/ | \
      grep -v https | \
      grep $my_substring | \
      grep latest-Linux-x86_64 | \
      sed -e 's@^[ ]*\([^ ]*\).* \([^ ]*\)$@'"$TARDIS"' upgrade_conda https://repo.continuum.io/miniconda/\1 \2@'
  }
  # This is a very ugly way to achieve what I want to do, but at present I cannot get a functional alternative to work.
  #   This is equivalent to running something like
  #     $TARDIS upgrade_conda https://repo.continuum.io/miniconda/Miniconda2-4.6.14-Linux-x86_64.sh  faa7cb0b0c8986ac3cacdbbd00fe4168
  my_command > $DIR/my_docker_command
  . $DIR/my_docker_command
  rm $DIR/my_docker_command
fi

if [  "$RESTORE_DATABASE" != "false" -o "$APPLY_CONFIG" != "false" ]; then
  # ensure that none of the containers in the compose file are instantiated
  echo "DIR is $DIR"
  $DIR/compose_stop.sh
  docker-compose -f $COMPOSE_FILE ps | grep galaxy-postgres || rootlesskit --disable-host-loopback bash -c "
  if [ -f $PGDATA_DIR/postmaster.pid ]; then
    rm $PGDATA_DIR/postmaster.pid
  fi
"
fi

### Retrieve data for export/config if requested, but don't apply it yet ###

SUCCESS=YES
if [ "$RETRIEVE_CONFIG" != "false" ]; then
  ($TARDIS retrieve_config && echo configuration retrieval succeeded) || SUCCESS=NO
  if [ "$SUCCESS" == "NO" ]; then
    echo "Configuration retrieval did not succeed"
    exit 1
  fi
else
  echo skipping configuration retrieval
fi

### Apply previously-retrieved data for export/config ###

SUCCESS=YES
if [ "$APPLY_CONFIG" != "false" ]; then
  if [ ! -d $EXPORT_DIR/backup/config ]; then
    echo "WARNING missing backup - $EXPORT_DIR/backup/config not found"
    exit 1
  fi
  ($TARDIS apply_config "${last_config}" && echo configuration application succeeded) || SUCCESS=NO
  if [ "$SUCCESS" == "NO" ]; then
    echo "Configuration application did not succeed"
    exit 1
  fi
else
  echo skipping configuration application
fi

### Retrieve and apply dataset data ###

SUCCESS=YES
if [ "$RESTORE_DATASETS" != "false" ]; then
  ($TARDIS restore_files && echo dataset-file restoration succeeded) || SUCCESS=NO
  if [ "$SUCCESS" == "NO" ]; then
    echo Dataset-file restoration failed or skipped
    exit 1
  fi
else
  echo skipping dataset-file restoration
fi

### Apply previously-retrieved database data ###

if [ "$RESTORE_DATABASE" != "false" ]; then
  ($TARDIS seed_database "${last_postgres}" && echo dataset-file restoration succeeded) || SUCCESS=NO
  if [ "$SUCCESS" == "NO" ]; then
    echo Database restoration failed or skipped
    exit 1
  fi
fi

# sh manage_db.sh upgrade
if [ "$UPGRADE_DATABASE" != "false" ]; then
  ($TARDIS upgrade_database && echo dataset-file restoration succeeded) || SUCCESS=NO
  if [ "$SUCCESS" == "NO" ]; then
    echo Database upgrade failed or skipped
    exit 1
  fi
fi

popd  # undo `pushd $DIR`

exit 0
