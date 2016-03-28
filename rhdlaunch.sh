#!/bin/bash

echo "---------------------"
echo "---- SITE LAUNCH ----"
echo "---------------------"

# $1: dev domain
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
read -p "Client admin email: " ADMINEMAIL
echo ""

echo "---------------------"
echo "--- Here we go... ---"
echo "---------------------"

# Into the dev dir...
cd $DEVROOT
cp -rv $1 $1.bak
mysqldump -u root -p"$DBROOTPASS" $DBNAME > $1.prelaunch.sql


# Run the migrate!
cd $DEVPATH
wp search-replace "//dev.roundhouse-designs.com/$1" "//$2"
wp option update admin_email "$ADMINEMAIL"

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


# Set final permissions
cd $DOMAINPATH/public
sudo find . -type f -exec chmod 664 {} \;
sudo find . -type d -exec chmod 774 {} \;
sudo chmod -R 775 wp-content
sudo mv wp-config.php ../
sudo chown -R www-data:www-data .

wp rewrite structure '/%postname%/'

echo '---------------------------------'
echo '------ You did it, tiger!! ------'
echo '---------------------------------'
