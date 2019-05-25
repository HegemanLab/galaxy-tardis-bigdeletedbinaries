#!/bin/bash
NOSUB=true
echo "$1" | grep -E '(^[01][0-9]$)|(^2[0-3]$)' && NOSUB=false
if [ "NOSUB_$NOSUB" ==  "NOSUB_false" ]; then
  sed -e "s/\<01\>/$1/" backup.crontab > backup.crontab.use
else
  cat backup.crontab > backup.crontab.use
fi
# Concatenating the crontab is an option, but it has no practical value for the TARDIS
#cat <(crontab -l) backup.crontab.use | crontab -
# Replace the crontab
crontab backup.crontab.use
# Show the resulting crontab
crontab -l
echo "Running cron daemon"
if [ ! -d /export/var/log ]; then
  mkdir -p /export/var/log
fi
crond -L /export/var/log/tardis-crond
sleep 1
# catch request to stop
trap "echo TERM caught; kill $(cat /var/run/dcron.pid); sleep 1; exit 1" TERM
# catch control-C
trap "echo INT caught;  kill $(cat /var/run/dcron.pid); sleep 1; exit 1" INT
echo "Tailing log - kill with TERM signal or by pressing control-C"
tail -f /export/var/log/tardis-crond

