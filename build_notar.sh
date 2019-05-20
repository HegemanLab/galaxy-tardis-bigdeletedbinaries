set -e
chmod +x support/busybox-static
chmod +x support/docker-usernetes
docker build -t tardis .
chmod -x support/docker-usernetes
chmod -x support/busybox-static
