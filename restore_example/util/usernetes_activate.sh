#!/bin/sh
if [ -z "$1" ]; then
  echo "usage: $0 path/to/decompressed/usernetes/release/"
  exit 1
fi
if [ ! -d "$1" ]; then
  echo "usage: $0 path/to/decompressed/usernetes/release/"
  echo "path '$1' does not exist"
  exit 1
fi
if [ ! -x "$1/bin/dockerd" ]; then
  echo "usage: $0 path/to/decompressed/usernetes/release/"
  echo "path '$1/bin/dockerd' does not exist"
  exit 1
fi
if [ ! -x "$1/bin/rootlesskit" ]; then
  echo "usage: $0 path/to/decompressed/usernetes/release/"
  echo "path '$1/bin/rootlesskit' does not exist"
  exit 1
fi
cd "$1"
# This is a shell archive (produced by GNU sharutils 4.15.2).
# To extract the files from this archive, save it to some FILE, remove
# everything before the '#!/bin/sh' line above, then type 'sh FILE'.
#
lock_dir=_sh08268
# Made on 2019-05-24 17:00 CDT by <art@Bombus>.
# Source directory was '/zpdrone/drone/home/art/src/galaxy-tardis/restore_example/util'.
#
# Existing files will *not* be overwritten, unless '-c' is specified.
#
# This shar contains:
# length mode       name
# ------ ---------- ------------------------------------------
#   3249 -rw-r--r-- bin/activate
#     75 -rw-r--r-- .bash_env
#
MD5SUM=${MD5SUM-md5sum}
f=`${MD5SUM} --version | egrep '^md5sum .*(core|text)utils'`
test -n "${f}" && md5check=true || md5check=false
${md5check} || \
  echo 'Note: not verifying md5sums.  Consider installing GNU coreutils.'
if test "X$1" = "X-c"
then keep_file=''
else keep_file=true
fi
echo=echo
save_IFS="${IFS}"
IFS="${IFS}:"
gettext_dir=
locale_dir=
set_echo=false

for dir in $PATH
do
  if test -f $dir/gettext \
     && ($dir/gettext --version >/dev/null 2>&1)
  then
    case `$dir/gettext --version 2>&1 | sed 1q` in
      *GNU*) gettext_dir=$dir
      set_echo=true
      break ;;
    esac
  fi
done

if ${set_echo}
then
  set_echo=false
  for dir in $PATH
  do
    if test -f $dir/shar \
       && ($dir/shar --print-text-domain-dir >/dev/null 2>&1)
    then
      locale_dir=`$dir/shar --print-text-domain-dir`
      set_echo=true
      break
    fi
  done

  if ${set_echo}
  then
    TEXTDOMAINDIR=$locale_dir
    export TEXTDOMAINDIR
    TEXTDOMAIN=sharutils
    export TEXTDOMAIN
    echo="$gettext_dir/gettext -s"
  fi
fi
IFS="$save_IFS"
if (echo "testing\c"; echo 1,2,3) | grep c >/dev/null
then if (echo -n test; echo 1,2,3) | grep n >/dev/null
     then shar_n= shar_c='
'
     else shar_n=-n shar_c= ; fi
else shar_n= shar_c='\c' ; fi
f=shar-touch.$$
st1=200112312359.59
st2=123123592001.59
st2tr=123123592001.5 # old SysV 14-char limit
st3=1231235901

if   touch -am -t ${st1} ${f} >/dev/null 2>&1 && \
     test ! -f ${st1} && test -f ${f}; then
  shar_touch='touch -am -t $1$2$3$4$5$6.$7 "$8"'

elif touch -am ${st2} ${f} >/dev/null 2>&1 && \
     test ! -f ${st2} && test ! -f ${st2tr} && test -f ${f}; then
  shar_touch='touch -am $3$4$5$6$1$2.$7 "$8"'

elif touch -am ${st3} ${f} >/dev/null 2>&1 && \
     test ! -f ${st3} && test -f ${f}; then
  shar_touch='touch -am $3$4$5$6$2 "$8"'

else
  shar_touch=:
  echo
  ${echo} 'WARNING: not restoring timestamps.  Consider getting and
installing GNU '\''touch'\'', distributed in GNU coreutils...'
  echo
fi
rm -f ${st1} ${st2} ${st2tr} ${st3} ${f}
#
if test ! -d ${lock_dir} ; then :
else ${echo} "lock directory ${lock_dir} exists"
     exit 1
fi
if mkdir ${lock_dir}
then ${echo} "x - created lock directory ${lock_dir}."
else ${echo} "x - failed to create lock directory ${lock_dir}."
     exit 1
fi
# ============= bin/activate ==============
if test ! -d 'bin'; then
  mkdir 'bin'
if test $? -eq 0
then ${echo} "x - created directory bin."
else ${echo} "x - failed to create directory bin."
     exit 1
fi
fi
if test -n "${keep_file}" && test -f 'bin/activate'
then
${echo} "x - SKIPPING bin/activate (file already exists)"

else
${echo} "x - extracting bin/activate (text)"
  sed 's/^X//' << 'SHAR_EOF' > 'bin/activate' &&
# This file must be used with "source bin/activate" *from bash*; you cannot run it directly
# Copy this file as "/path/to/usernetes/bin/activate", 
#   where "/path/to/usernetes/bin" is the path to the directory with the decompressed
#   contents of the usernetes ".tbz" file that you have downloaded from
#   https://github.com/rootless-containers/usernetes/releases
X
deactivate () {
X    # reset old environment variables
X    if [ -n "$_OLD_VIRTUAL_PATH" ] ; then
X        PATH="$_OLD_VIRTUAL_PATH"
X        export PATH
X        unset _OLD_VIRTUAL_PATH
X    fi
X    if [ -n "$_OLD_VIRTUAL_PYTHONHOME" ] ; then
X        PYTHONHOME="$_OLD_VIRTUAL_PYTHONHOME"
X        export PYTHONHOME
X        unset _OLD_VIRTUAL_PYTHONHOME
X    fi
X
X    # This should detect bash and zsh, which have a hash command that must
X    # be called to get it to forget past commands.  Without forgetting
X    # past commands the $PATH changes we made may not be respected
X    if [ -n "$BASH" -o -n "$ZSH_VERSION" ] ; then
X        hash -r
X    fi
X
X    if [ -n "$_OLD_VIRTUAL_PS1" ] ; then
X        PS1="$_OLD_VIRTUAL_PS1"
X        export PS1
X        unset _OLD_VIRTUAL_PS1
X    fi
X
X    unset VIRTUAL_ENV
X    if [ ! "$1" = "nondestructive" ] ; then
X    # Self destruct!
X        unset -f deactivate
X    fi
X    export EXPORT_OPTIONS='-n'
X    if [ -n "$ENV" ] ; then
X        source ${ENV}
X    fi
X    export -n BASH_ENV
X    export -n ENV
X    export -n EXPORT_OPTIONS
X    unset BASH_ENV
X    unset ENV
X    unset EXPORT_OPTIONS
}
X
# unset irrelavent variables
deactivate nondestructive
X
# set the actual script directory per https://stackoverflow.com/a/246128
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
X  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
X  SOURCE="$(readlink "$SOURCE")"
X  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
X
pushd ${DIR}/.. > /dev/null
VIRTUAL_ENV=`pwd`
export VIRTUAL_ENV
X
_OLD_VIRTUAL_PATH="$PATH"
export PATH="$VIRTUAL_ENV/bin:$PATH"
X
# unset PYTHONHOME if set
# this will fail if PYTHONHOME is set to the empty string (which is bad anyway)
# could use `if (set -u; : $PYTHONHOME) ;` in bash
if [ -n "$PYTHONHOME" ] ; then
X    _OLD_VIRTUAL_PYTHONHOME="$PYTHONHOME"
X    unset PYTHONHOME
fi
X
if [ -z "$VIRTUAL_ENV_DISABLE_PROMPT" ] ; then
X    _OLD_VIRTUAL_PS1="$PS1"
X    if [ "x(usernetes) " != x ] ; then
X	PS1="(usernetes) $PS1"
X    else
X    if [ "`basename \"$VIRTUAL_ENV\"`" = "__" ] ; then
X        # special case for Aspen magic directories
X        # see http://www.zetadev.com/software/aspen/
X        PS1="[`basename \`dirname \"$VIRTUAL_ENV\"\``] $PS1"
X    else
X        PS1="(`basename \"$VIRTUAL_ENV\"`)$PS1"
X    fi
X    fi
X    export PS1
fi
X
# This should detect bash and zsh, which have a hash command that must
# be called to get it to forget past commands.  Without forgetting
# past commands the $PATH changes we made may not be respected
if [ -n "$BASH" -o -n "$ZSH_VERSION" ] ; then
X    hash -r
fi
X
export ENV=${VIRTUAL_ENV}/.bash_env
source ${ENV}
export BASH_ENV=$ENV
X
popd > /dev/null
SHAR_EOF
  (set 20 19 05 24 16 24 41 'bin/activate'
   eval "${shar_touch}") && \
  chmod 0644 'bin/activate'
if test $? -ne 0
then ${echo} "restore of bin/activate failed"
fi
  if ${md5check}
  then (
       ${MD5SUM} -c >/dev/null 2>&1 || ${echo} 'bin/activate': 'MD5 check failed'
       ) << \SHAR_EOF
a0bebd21cc02870c155aa5eda25482d6  bin/activate
SHAR_EOF

else
test `LC_ALL=C wc -c < 'bin/activate'` -ne 3249 && \
  ${echo} "restoration warning:  size of 'bin/activate' is not 3249"
  fi
fi
# ============= .bash_env ==============
if test -n "${keep_file}" && test -f '.bash_env'
then
${echo} "x - SKIPPING .bash_env (file already exists)"

else
${echo} "x - extracting .bash_env (text)"
  sed 's/^X//' << 'SHAR_EOF' > '.bash_env' &&
export ${EXPORT_OPTIONS} DOCKER_HOST=unix://${XDG_RUNTIME_DIR}/docker.sock
SHAR_EOF
  (set 20 19 05 24 16 59 14 '.bash_env'
   eval "${shar_touch}") && \
  chmod 0644 '.bash_env'
if test $? -ne 0
then ${echo} "restore of .bash_env failed"
fi
  if ${md5check}
  then (
       ${MD5SUM} -c >/dev/null 2>&1 || ${echo} '.bash_env': 'MD5 check failed'
       ) << \SHAR_EOF
6a8ad1aceeb289b2babe41f65ea63c5d  .bash_env
SHAR_EOF

else
test `LC_ALL=C wc -c < '.bash_env'` -ne 75 && \
  ${echo} "restoration warning:  size of '.bash_env' is not 75"
  fi
fi
if rm -fr ${lock_dir}
then ${echo} "x - removed lock directory ${lock_dir}."
else ${echo} "x - failed to remove lock directory ${lock_dir}."
     exit 1
fi
exit 0
