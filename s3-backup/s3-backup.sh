#!/bin/sh
DIR=/home/gaswirth/scripts/s3-backup
EXCLUDES="$DIR"/s3.exclude
HOSTNAME=`hostname`

echo "S3 Backup Started on $HOSTNAME"
date +'%a %b %e %H:%M:%S %Z %Y'
s3cmd sync --delete-removed --recursive --preserve --exclude-from $EXCLUDES /home s3://linode-$LINODE
s3cmd sync --delete-removed --recursive --preserve --exclude-from $EXCLUDES /etc s3://linode-$LINODE
s3cmd sync --delete-removed --recursive --preserve --exclude-from $EXCLUDES /var s3://linode-$LINODE
dpkg --get-selections > "$DIR"/dpkg.list
s3cmd sync --preserve "$DIR"/dpkg.list s3://linode-$LINODE
date +'%a %b %e %H:%M:%S %Z %Y'
echo 'Finished'
