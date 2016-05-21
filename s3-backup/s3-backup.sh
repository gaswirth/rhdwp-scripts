#!/bin/sh
EXCLUDES=/home/gaswirth/scripts/s3-backup/s3.exclude
LINODE=$1

echo 'S3 Backup Started'
date +'%a %b %e %H:%M:%S %Z %Y'
s3cmd sync --delete-removed --recursive --preserve --exclude-from $EXCLUDES /home s3://linode-$LINODE
s3cmd sync --delete-removed --recursive --preserve --exclude-from $EXCLUDES /etc s3://linode-$LINODE
s3cmd sync --delete-removed --recursive --preserve --exclude-from $EXCLUDES /var s3://linode-$LINODE
dpkg --get-selections > /home/gaswirth/s3-backup-dpkg.list
s3cmd sync --preserve /home/gaswirth/s3-backup-dpkg.list s3://linode-$LINODE
date +'%a %b %e %H:%M:%S %Z %Y'
echo 'Finished'
