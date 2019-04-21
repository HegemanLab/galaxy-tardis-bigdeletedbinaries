FROM alpine:3.9.3
#FROM ubuntu:18.04
MAINTAINER Art Eschenlauer, esch0041@umn.edu
#ENV DEBIAN_FRONTEND noninteractive
#RUN apt-get update && apt-get install -y ubuntu-server
#RUN apt-get upgrade -y
#RUN apt-get install -y cvs s3cmd
RUN apk add bash cvs curl fossil
RUN apk add --no-cache py-pip && pip install s3cmd
#RUN curl https://get.docker.com/ | sh
# copy docker binary from https://github.com/rootless-containers/usernetes/releases/tag/v20190212.0
COPY docker /usr/local/bin/docker
COPY s3/live_file_backup.sh /opt/s3/live_file_backup.sh
COPY s3/bucket_backup.sh /opt/s3/bucket_backup.sh
#COPY s3/dest.config /opt/s3/dest.config
#COPY s3/dest.s3cfg /opt/s3/dest.s3cfg
COPY support/transmit_backup.sh /opt/support/transmit_backup.sh
COPY support/cvs /opt/support/cvs
COPY support/config_xml_dump.sh /opt/support/config_xml_dump.sh
COPY support/db_dump.sh /opt/support/db_dump.sh
COPY support/download_file_bucket.sh /opt/support/download_file_bucket.sh
COPY support/run_backup.sh /opt/support/run_backup.sh
COPY support/tardis.sh /opt/support/tardis.sh
COPY init /opt/init
RUN chmod +x /opt/init
RUN ln -s /opt/init /usr/local/bin/tardis
ENTRYPOINT ["/opt/init"]
COPY Dockerfile /opt/support/Dockerfile
