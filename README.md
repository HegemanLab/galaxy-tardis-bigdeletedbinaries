
# How to use this repository to support Pisces V

I created this repository to implement a back-up path to store the configuration and datasets from Galaxy in CephS3 storage at the University of Minnesota.  I have used this strategy to back up and restore histories, workflows, and datasets through several iterations of the `Pisces` instance.  This is for the fifth iteration, `Pisces V`, when I have the chance to bring it up, populating it from the backup of `Pisces IV`.

The very terse summary is to invoke a backup on Galomix2 in two steps:
```bash
# Collect configuration data from the running instance.
sudo ssh galaxy rootlesskit --disable-host-loopback bash /datapool/galaxy/home/piquint/export/tardis.sh backup
# Transmit the configuration, histories, datasets, and even shed tools to CephS3 storage at MSI.
sudo ssh galaxy rootlesskit --disable-host-loopback bash /datapool/galaxy/home/piquint/export/tardis.sh transmit
```

In the long run I hope to make this more generalized.  Right now this exists to help me maintain our production Galaxy instance.

# How to use ths repository more generally - use docker

## build

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

## run

The TARDIS needs to use docker to run commands in the other containers.  Therefore, you will need to forward the dockerd socket into the container, as shown below.

It is likely you will include this in a composition.  If you don't, you will invoke it as:
```
# using rootless dockerd on usernetes
TARDIS="docker run --rm -ti -v ${XDG_RUNTIME_DIR}/docker.sock:/var/run/docker.sock -v /path/to/export:/export --name tardis tardis"
# running dockerd as root
TARDIS="sudo docker run --rm -ti -v /var/run/docker.sock:/var/run/docker.sock -v /path/to/export:/export --name tardis tardis"
# Collect configuration data from the running instance.
$TARDIS backup
# Transmit the configuration, histories, datasets, and even shed tools to CephS3 storage at MSI.
$TARDIS export
```
If you do use the TARDIS in a composition, use the above as a guide.

# CVS

## Why use CVS rather than Git?

CVS (Concurrent Versions System, [https://www.nongnu.org/cvs/](https://www.nongnu.org/cvs/)) stores all revisions of a text file in an extremely compact format.  This project backs up the Galaxy database to a single SQL file.  Multiple revisions of this file take up an much larger space in a Git repository, whereas, in a CVS repository, they take up little more room than a few times the size of the SQL file.  CVS has been replaced for general software development, but it seems to fill a good niche here.  On the other hand, a more compelling question might be "Why use CVS rather than RCS?", since both CVS and RCS use the same storage format - maybe CVS is more familiar and easier to install (CVS has a single binary, compared to nine for RCS).

There may be a modern source control system that could achieve compact storage and a single binary.  Fossil ([https://www.fossil-scm.org/](https://www.fossil-scm.org/)) seems like a possible candidate, but I have not yet worked with it enough to become familiar with its operation and security model.

## Statically linked `cvs` binary

The `support/cvs-static` binary was compiled and statically linked as described at [https://github.com/eschen42/alpine-cbuilder#a-use-case](https://github.com/eschen42/alpine-cbuilder#a-use-case)
