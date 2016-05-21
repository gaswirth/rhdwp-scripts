#!/bin/sh
echo 'S3 Backup Started'
date +'%a %b %e %H:%M:%S %Z %Y'
s3cmd sync --delete-removed --recursive --preserve --exclude-from /home/gaswirth/scripts/s3-backup/s3.exclude /home s3://linode-joanna
s3cmd sync --delete-removed --recursive --preserve --exclude-from /home/gaswirth/scripts/s3-backup/s3.exclude /etc s3://linode-joanna
s3cmd sync --delete-removed --recursive --preserve --exclude-from /home/gaswirth/scripts/s3-backup/s3.exclude /var s3://linode-joanna
dpkg --get-selections > /home/gaswirth/scripts/s3-backup/dpkg.list
s3cmd sync --preserve /home/gaswirth/scripts/s3-backup/dpkg.list s3://linode-joanna
date +'%a %b %e %H:%M:%S %Z %Y'
echo 'Finished'
