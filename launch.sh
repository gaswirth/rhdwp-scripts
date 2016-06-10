#!/bin/bash

echo "---------------------"
echo "---- SITE LAUNCH ----"
echo "---------------------"

# $1: dev directory
# $2: launch domain

DEVROOT="/var/www/public_html/dev.roundhouse-designs.com/public"
DEVDIR=$1
DOMAIN=$2
DEVPATH=$DEVROOT/$1
DOMAINPATH=/var/www/public_html/$2
APACHEDIR=/etc/apache2/sites-available
APACHEFILE=$2.conf

echo "Launching $1 to $2"

read -p "Database name: " DBNAME
read -s -p "Database admin password: " DBROOTPASS
echo ""
read -p "Client admin email: " ADMINEMAIL
echo ""

echo "---------------------"
echo "--- Here we go... ---"
echo "---------------------"

# Into the dev dir...
cd $DEVROOT
cp -rv $1 $1.bak
mysqldump -u root -p"$DBROOTPASS" $DBNAME > $1.prelaunch.sql


# Update Core and Plugins, then run the migrate!
cd $DEVPATH
wp option update admin_email "$ADMINEMAIL"
wp core update
wp plugin update --all
wp search-replace "https://dev.roundhouse-designs.com/$1" "http://$2"
wp search-replace "http://dev.roundhouse-designs.com/$1" "http://$2"

# Create and move to the launch directory
mkdir $DOMAINPATH
mkdir $DOMAINPATH/public
mkdir $DOMAINPATH/log
cp -r $DEVPATH/* $DOMAINPATH/public
rm -rf $DEVPATH

# Apache work
cd $APACHEDIR
sudo cp _template.conf $APACHEFILE
sudo sed -i "s/domain\.com/$2/g" $APACHEFILE
sudo a2ensite $APACHEFILE
sudo service apache2 reload


# Run last WP-CLI actions and set final permissions
cd $DOMAINPATH/public
wp rewrite flush --hard
wp plugin activate w3-total-cache

sudo find . -name '*.dead' -exec rm {} \;
sudo find . -type f -exec chmod 664 {} \;
sudo find . -type d -exec chmod 774 {} \;
sudo chmod -R 775 wp-content
sudo sed -i "s/'WP_DEBUG_LOG', true/'WP_DEBUG_LOG', false/i" wp-config.php
sudo sed -i "s/'WP_MEMORY_LIMIT', '-1'/'WP_MEMORY_LIMIT', '96M'/i" wp-config.php
sudo mv wp-config.php ../
sudo chown -R www-data:www-data .

echo '---------------------------------'
echo '------ You did it, tiger!! ------'
echo '---------------------------------'