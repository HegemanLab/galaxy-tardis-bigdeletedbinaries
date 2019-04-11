#!/bin/bash
# ref: https://stackoverflow.com/a/16042226
# Use this command, including the trailing slashes on directory names:

s3cmd --skip-existing -c /export/s3/msi_galaxym.s3cfg sync s3://msigalaxym-piscesw/000/ /export/galaxy-central/database/files/000/
s3cmd --skip-existing -c /export/s3/msi_galaxym.s3cfg sync s3://msigalaxym-piscesw/001/ /export/galaxy-central/database/files/001/
s3cmd --skip-existing -c /export/s3/msi_galaxym.s3cfg sync s3://msigalaxym-piscesw/002/ /export/galaxy-central/database/files/002/
s3cmd --skip-existing -c /export/s3/msi_galaxym.s3cfg sync s3://msigalaxym-piscesw/003/ /export/galaxy-central/database/files/003/
s3cmd --skip-existing -c /export/s3/msi_galaxym.s3cfg sync s3://msigalaxym-piscesw/004/ /export/galaxy-central/database/files/004/
s3cmd --skip-existing -c /export/s3/msi_galaxym.s3cfg sync s3://msigalaxym-piscesw/005/ /export/galaxy-central/database/files/005/
s3cmd --skip-existing -c /export/s3/msi_galaxym.s3cfg sync s3://msigalaxym-piscesw/006/ /export/galaxy-central/database/files/006/
s3cmd --skip-existing -c /export/s3/msi_galaxym.s3cfg sync s3://msigalaxym-piscesw/007/ /export/galaxy-central/database/files/007/
s3cmd --skip-existing -c /export/s3/msi_galaxym.s3cfg sync s3://msigalaxym-piscesw/008/ /export/galaxy-central/database/files/008/
