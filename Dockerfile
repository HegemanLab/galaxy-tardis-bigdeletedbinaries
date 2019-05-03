FROM alpine:3.9.3
MAINTAINER Art Eschenlauer, esch0041@umn.edu
RUN apk add bash curl fossil
RUN apk add --no-cache py-pip && pip install s3cmd
# copy docker binary from https://github.com/rootless-containers/usernetes/releases/tag/v20190212.0
COPY docker                                  /usr/local/bin/docker
COPY support/cvs-static                      /opt/support/cvs
RUN  ln              /opt/support/cvs        /usr/local/bin/cvs
COPY s3/live_file_backup.sh                  /opt/s3/live_file_backup.sh
COPY s3/live_file_restore.sh                 /opt/s3/live_file_restore.sh
COPY s3/bucket_backup.sh                     /opt/s3/bucket_backup.sh
COPY s3/bucket_retrieve.sh                   /opt/s3/bucket_retrieve.sh
COPY support/transmit_backup.sh              /opt/support/transmit_backup.sh
COPY support/retrieve_backup.sh              /opt/support/retrieve_backup.sh
COPY support/config_xml_dump.sh              /opt/support/config_xml_dump.sh
COPY support/db_dump.sh                      /opt/support/db_dump.sh
COPY support/download_file_bucket.sh         /opt/support/download_file_bucket.sh
COPY support/run_backup.sh                   /opt/support/run_backup.sh
COPY support/tardis.sh                       /opt/support/tardis.sh
COPY init                                    /opt/init
RUN chmod +x /opt/init
RUN ln -s /opt/init /usr/local/bin/tardis
RUN sed -i -e 's/^postgres:x:[^:]*:[^:]*:/postgres:x:999:999:/' /etc/passwd
RUN sed -i -e 's/^postgres:x:[^:]*:/postgres:x:999:/'           /etc/group
RUN adduser -s /bin/bash -h /export -D -H -u 1450 -g "Galaxy-file owner" galaxy
ENTRYPOINT ["/opt/init"]
COPY Dockerfile /opt/support/Dockerfile
