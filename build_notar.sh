set -e
if [ ! -f support/docker-usernetes ]; then
  pushd support
  wget https://github.com/HegemanLab/galaxy-tardis/releases/download/v0.1.0/docker-usernetes.gz --output-document docker-usernetes.gz
  gzip -d docker-usernetes.gz
  popd
fi
chmod +x support/busybox-static
chmod +x support/docker-usernetes
docker build -t tardis .
chmod -x support/docker-usernetes
chmod -x support/busybox-static
