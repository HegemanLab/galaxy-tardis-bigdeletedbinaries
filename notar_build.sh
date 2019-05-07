set -e
chmod +x support/busybox-static
docker build -t tardis .
chmod -x support/busybox-static
