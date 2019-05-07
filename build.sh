#  The `tar` command -h  options dereference logical links when instantiating the build environment,
#    (inspired by https://github.com/moby/moby/issues/18789#issuecomment-165985865).
set -e
chmod +x support/busybox-static
tar ch . | docker build -t tardis -
chmod -x support/busybox-static
