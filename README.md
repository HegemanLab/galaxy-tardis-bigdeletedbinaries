
# How to use this repository to support Pisces V

I created this repository to implement a back-up path to store the configuration and datasets from Galaxy in CephS3 storage at the University of Minnesota.  I have used this strategy to back up and restore histories, workflows, and datasets through several iterations of the `Pisces` instance.  This is for the fifth iteration, `Pisces V`, when I have the chance to bring it up, populating it from the backup of `Pisces IV`.

The very terse summary is to invoke a backup on Galomix2 in two steps:
```bash
# Collect configuration data from the running instance.
sudo ssh galaxy rootless bash /datapool/galaxy/home/piquint/export/tardis.sh backup
# Transmit the configuration, histories, datasets, and even shed tools to CephS3 storage at MSI.
sudo ssh galaxy rootless bash /datapool/galaxy/home/piquint/export/tardis.sh transmit
```

In the long run I hope to make this more generalized.  Right now this exists to help me maintain our production Galaxy instance.

# How to use ths repository more generally

- [ ] Copy or symlink `s3/dest.config.example` and `s3/dest.s3cfg.example` to `s3/dest.config` and `s3/dest.s3cfg` and adjust
  - `access_key`
  - `secret_key`
  - `FILE_BUCKET`
  - `CONFIG_BUCKET`
  - `EXPORT_ROOT`
- [ ] *If you didn't use symlinks,* then run `docker build -t .` from the directory containing this README.md file.
- [ ] *If you used symlinks,* then run `tar ch . | docker build -t tardis -` from the directory containing this README.md file.
  - The `tar` command was added per [https://github.com/moby/moby/issues/18789#issuecomment-165985865](https://github.com/moby/moby/issues/18789#issuecomment-165985865) to dereference logical links when instantiating the build environment.
  - It says in `man docker-build` that, when a URL to a tarball is supplied, `docker build` will use that tarball as the build context rather than the current directory.
  - Apparently, this works when the standard input is a tarball as well, although the man page does not say so explicitly.  Hopefully this capability won't vanish in the future.
