# TARDIS - Temporal Archive Remote Distribution and Installation System

The purpose of this Docker image is to back up and restore Galaxy instances that are based on [galaxy-docker-stable](https://github.com/bgruening/docker-galaxy-stable/).  The only storage back-end implemented thus far is S3-compatible storage such as Ceph.

Usage for the `suppport/tardis` script is as follows:
```
  tardis backup                - Back up PostgreSQL database and galaxy-central/config.
  tardis transmit              - Transmit datasets and backup to Amazon-S3-compatible storage.
  tardis retrieve_config       - Retrieve database and config backup (but not datasets) from S3.
  tardis apply_config [date]   - Restore config from backup, whether from S3 or "tardis backup".
  tardis restore_files         - Retrieve datasets from S3 (not desirable when using object store).
  tardis seed_database [date]  - Replace PostgreSQL database with copy from backup.
  tardis purge_empty_tmp_dirs  - Purge empty tmp directories that accumulate with datasets.
  tardis cron                  - Run dcron NOT as daemon to run backup daily.
  tardis upgrade_database      - Upgrade the PostgreSQL database to match the Galaxy version.

  tardis upgrade_conda [url_or_path] [md5sum]
                               - Upgrade conda (e.g. from https://repo.continuum.io/miniconda/).
  tardis bash                  - Enter a bash shell, if applicable.
```

# How to use ths repository

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

Other commands will require other environment variables; see `tags-for-tardis_envar-to-source.sh.example`.  For convenience, when you source the `tardis_envar.sh` script, it reads variables from `tags-for-tardis_envar-to-source.sh` and sets up the `TARDIS` variable accordingly.

# CVS

## Why use CVS rather than Git?

CVS (Concurrent Versions System, [https://www.nongnu.org/cvs/](https://www.nongnu.org/cvs/)) stores all revisions of a text file in an extremely compact format.  This project backs up the Galaxy database to a single SQL file.  Multiple revisions of this file take up an much larger space in a Git repository, whereas, in a CVS repository, they take up little more room than a few times the size of the SQL file.  CVS has been replaced for general software development, but it seems to fill a good niche here.  On the other hand, a more compelling question might be "Why use CVS rather than RCS?", since both CVS and RCS use the same storage format - maybe CVS is more familiar and easier to install (CVS has a single binary, compared to nine for RCS).

There may be a modern source control system that could achieve compact storage and a single binary.  Fossil ([https://www.fossil-scm.org/](https://www.fossil-scm.org/)) seems like a possible candidate, but I have not yet worked with it enough to become familiar with its operation and security model.

## Statically linked `cvs` binary

The `support/cvs-static` binary was compiled and statically linked as described at [https://github.com/eschen42/alpine-cbuilder#a-use-case](https://github.com/eschen42/alpine-cbuilder#a-use-case)

# Docker client

The `support/docker-usernetes` binary is a statically linked binary that was extracted from:
[https://github.com/rootless-containers/usernetes/releases/tag/v20190511.1](https://github.com/rootless-containers/usernetes/releases/tag/v20190511.1)
as follows:
```bash
wget https://github.com/rootless-containers/usernetes/releases/download/v20190511.1/usernetes-x86_64.tbz
bzip2 -d usernetes-x86_64.tbz
tar -xvf usernetes-x86_64.tar usernetes/bin/docker
cp usernetes/bin/docker support/docker-usernetes
rm -rf usernetes-x86_64.tar usernetes
```
