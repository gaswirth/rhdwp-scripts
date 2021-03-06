#!/bin/bash

echo "*******************"
echo "* B2 Backup Setup *"
echo "*******************"

HN=`hostname`
PUBKEY=`cat /home/gaswirth/.ssh/id_rsa.pub`

read -n 1 -s -r -p "Please create a 'linode-$HN' B2 Bucket, then press any key to continue..."
echo ""

mkdir /home/gaswirth/scripts
cd /home/gaswirth/scripts

# Restic backups
wget https://raw.githubusercontent.com/gaswirth/rhdwp-scripts/forked-repos/restic-backup.sh
chmod u+x restic-backup.sh
sudo chown gaswirth:gaswirth restic-backup.sh

export B2_ACCOUNT_ID="4bc42f267688"
export B2_ACCOUNT_KEY="00244196b19d8095255129a248f5e2eff1fd383a52"

restic -r "b2:linode-$HN" init
touch .restic

read -s -p "Save the following B2 Bucket password in .restic: " BUCKETPASS
echo "$BUCKETPASS" > .restic
chmod 400 .restic

echo ""
echo "----------------------"

# SASL for memcached
sudo apt-get install sasl2-bin -y
sudo mkdir -p /etc/sasl2
sudo cat > /etc/sasl2/memcached.conf <<- EOF
	mech_list: plain
	log_level: 5
	sasldb_path: /etc/sasl2/memcached-sasldb2
EOF
sudo saslpasswd2 -a memcached -c -f /etc/sasl2/memcached-sasldb2 gaswirth
sudo chown memcache:memcache /etc/sasl2/memcached-sasldb2
sudo systemctl restart memcached

echo ""
echo "----------------------"
echo "PLEASE ADD public the following key to GitHub.com:"
echo ""
echo "$PUBKEY"
echo ""
echo ""
echo "***** Done! *****"
