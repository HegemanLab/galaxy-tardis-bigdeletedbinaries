#!/bin/bash
set -e
set -x # verbose
echo ---
echo `date --iso-8601=seconds` Backup starting

# dump the galaxy exported configuration xml files
/export/support/config_xml_dump.sh

# dump the SQL DDL and DML to reconstruct and repopulate the database, respectively
/export/support/db_dump.sh

# record a copy of configuration settings passed through environment variables
printenv | sort | grep GALAXY_CONFIG_ > /export/backup/galaxy_config_env.txt

# save the files used to copy data and config to the bucket (outside of Galaxy)
/export/s3/bucket_backup.sh /export/s3/
/export/s3/bucket_backup.sh /export/backup/
/export/s3/bucket_backup.sh /export/support/

# save Galaxy config files necessary to restore the UI
/export/s3/bucket_backup.sh /export/galaxy-central/config/object_store_conf.xml
/export/s3/bucket_backup.sh /export/galaxy-central/config/shed_tool_conf.xml
/export/s3/bucket_backup.sh /export/galaxy-central/config/tool_conf.xml
/export/s3/bucket_backup.sh /export/galaxy-central/integrated_tool_panel.xml


# save the tools and shed_tools
/export/s3/bucket_backup.sh /export/galaxy-central/tools.yaml
/export/s3/bucket_backup.sh /export/shed_tools/

echo `date --iso-8601=seconds` Backup finishing
echo ...

/export/s3/bucket_backup.sh /export/var/log/run_backup.log
