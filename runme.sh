#!/bin/bash

echo "*****************"
echo " B2 Backup Setup"
echo "*****************"

HN=`hostname`

read -n 1 -s -r -p "Please create a 'linode-$HN' B2 Bucket, then press any key to continue..."
echo ""

mkdir /home/gaswirth/scripts
cd /home/gaswirth/scripts
wget https://raw.githubusercontent.com/gaswirth/rhdwp-scripts/forked-repos/restic-backup.sh
chmod u+x restic-backup.sh
sudo chown gaswirth:gaswirth restic-backup.sh

export B2_ACCOUNT_ID="4bc42f267688"
export B2_ACCOUNT_KEY="00244196b19d8095255129a248f5e2eff1fd383a52"

restic -r "b2:linode-$HN" init
touch .restic

read -p "Save the following B2 Bucket password in .restic: " BUCKETPASS
echo "$BUCKETPASS" > .restic
chmod 400 .restic

echo "***********"
echo "** TASKS **"
echo "***********"
echo "-----------"
echo "PLEASE EDIT apache2.conf AND CHANGE AllowOverride None in /var/www/ vhost to AllowOverride All"
echo "-----------"
echo "PLEASE ADD public the following key to GitHub.com: $PUBKEY"
echo "-----------"

echo "*****************"
echo " Done!"
echo "*****************"