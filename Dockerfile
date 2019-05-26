FROM alpine:3.9.3
MAINTAINER Art Eschenlauer, esch0041@umn.edu
# Add required galaxy and postgres accounts
RUN sed -i -e 's/^postgres:x:[^:]*:[^:]*:/postgres:x:999:999:/' /etc/passwd
RUN sed -i -e 's/^postgres:x:[^:]*:/postgres:x:999:/'           /etc/group
RUN adduser -s /bin/bash -h /export -D -H -u 1450 -g "Galaxy-file owner" galaxy

# The coreutils binary adds a megabyte to the image size,
#   but it gives some required invocation options for 'date'
RUN apk add coreutils
# Including bash (required), curl (handy)
RUN apk add bash curl python3
# Support scheduled activity, e.g., daily backups
RUN apk add dcron
# Support documentation in the unix-manual format
RUN apk add man && bash -c 'for i in {1..8}; do mkdir -p /usr/local/man/man${i}; done'
# To get all of the standard man pages themselves, you could uncomment the next line,
#   but note that it nearly doubles the size of the image.
#RUN apk add man-pages
# Support the vim editor
RUN apk add vim

# Fix "pip not found" error and suppress warning about outdated pip, if any
RUN pip3 install --upgrade pip
# Include s3cmd for transmitting files to Amazon-S3 compatible buckets.  See e.g.:
#   https://en.wikipedia.org/wiki/Amazon_S3#S3_API_and_competing_services
RUN pip install s3cmd

# Substitute statically linked busybox so that it can be shared with glibc-based containers
#   See https://github.com/eschen42/alpine-cbuilder#statically-linked-busybox
#   and https://github.com/HegemanLab/galaxy-tardis/releases/tag/binary1-pre
RUN mkdir -p /opt/support && \
    cd       /opt/support && \
    wget https://github.com/HegemanLab/galaxy-tardis/releases/download/binary1-pre/busybox-static.gz --output-document busybox.gz && \
    gzip -d busybox.gz && \
    chmod +x busybox
RUN ln -f /opt/support/busybox               /bin/busybox

# The coreutils binary adds a megabyte to the image size,
#   but it gives some required invocation options for 'date'
RUN apk add coreutils
# Including bash (required), curl (handy)
RUN apk add bash curl
# Include s3cmd for transmitting files to Amazon-S3 compatible buckets.  See e.g.:
#   https://en.wikipedia.org/wiki/Amazon_S3#S3_API_and_competing_services
RUN apk add py-pip && pip install s3cmd
# Support scheduled activity, e.g., daily backups
RUN apk add dcron

# Add statically linked docker binary
#   See https://github.com/rootless-containers/usernetes/releases/tag/v20190212.0
#   and https://github.com/HegemanLab/galaxy-tardis/releases/tag/binary1-pre
RUN mkdir -p /usr/local/bin && \
    cd       /usr/local/bin && \
    wget https://github.com/HegemanLab/galaxy-tardis/releases/download/binary1-pre/docker-usernetes.gz --output-document docker.gz && \
    gzip -d docker.gz && \
    chmod +x docker && \
    cd ..

# Add statically linked cvs binary so that it can be shared with glibc-based containers
#   See https://github.com/eschen42/alpine-cbuilder#cvs-executable-independent-of-glibc
#   and https://github.com/HegemanLab/galaxy-tardis/releases/tag/binary1-pre
RUN cd /opt/support && \
    wget https://github.com/HegemanLab/galaxy-tardis/releases/download/binary1-pre/cvs-static.gz --output-document cvs.gz && \
    gzip -d cvs.gz && \
    chmod +x cvs
RUN ln       /opt/support/cvs                /usr/local/bin/cvs

# Support file, configuration, and database backup and restore with S3-compatible block storage
COPY s3/live_file_backup.sh                  /opt/s3/live_file_backup.sh
COPY s3/live_file_restore.sh                 /opt/s3/live_file_restore.sh
COPY s3/bucket_backup.sh                     /opt/s3/bucket_backup.sh
COPY s3/bucket_retrieve.sh                   /opt/s3/bucket_retrieve.sh
# S3-independent scripts to support backup and restore
COPY support/transmit_backup.sh              /opt/support/transmit_backup.sh
COPY support/retrieve_backup.sh              /opt/support/retrieve_backup.sh
# Dump galaxy configuration files and downloaded shed tools
COPY support/config_xml_dump.sh              /opt/support/config_xml_dump.sh
COPY support/pgadmin_dump.sh                 /opt/support/pgadmin_dump.sh
# Load galaxy configuration files and downloaded shed tools
COPY support/config_seed.sh                  /opt/support/config_seed.sh
# Upgrade miniconda as needed
COPY support/conda_upgrade.sh                /opt/support/conda_upgrade.sh
# Dump and load PostgreSQL database
COPY support/db_dump.sh                      /opt/support/db_dump.sh
COPY support/db_seed.sh                      /opt/support/db_seed.sh
# Core executable for the TARDIS container
COPY support/tardis                          /opt/support/tardis
COPY support/tardis_setup                    /opt/support/tardis_setup
# Daily backup cron task
COPY support/backup.crontab                  /opt/support/backup.crontab
COPY support/cron.sh                         /opt/support/cron.sh
# Entrypoint executable
COPY init                                    /opt/init
# Support documentation in the unix-manual format
RUN apk add man && bash -c 'for i in {1..8}; do mkdir -p /usr/local/man/man${i}; done'
# To get the man pages themselves, uncomment the next line, but note that it nearly doubles the size of the image 
#RUN apk add man-pages
# Support the vim editor
RUN apk add vim
# Executable-file permissions (besides busybox and cvs because they are hard-linked)
RUN chmod +x                                 /opt/init
RUN chmod +x                                 /opt/s3/*.sh
RUN chmod +x                                 /opt/support/*.sh
RUN chmod +x                                 /opt/support/tardis
# Set the entry point
ENTRYPOINT ["/opt/init"]
# Provide intra-container copy of this container-definition
COPY Dockerfile /opt/support/Dockerfile
