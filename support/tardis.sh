#!/bin/bash
#  Note well: Execute these from *outside* a container
docker exec galaxy-init bash -c "ln -s /export/support/cvs /usr/local/bin/cvs; /export/support/config_xml_dump.sh; rm /usr/local/bin/cvs"
docker exec galaxy-postgres /export/support/db_dump.sh

