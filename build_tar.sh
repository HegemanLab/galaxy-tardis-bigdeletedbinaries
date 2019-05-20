#  The `tar` command -h  options dereference logical links when instantiating the build environment,
#    (inspired by https://github.com/moby/moby/issues/18789#issuecomment-165985865).
set -e
tar ch --exclude='./restore_example' . | docker build -t tardis -
