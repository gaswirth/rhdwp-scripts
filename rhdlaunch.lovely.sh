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

DBNAME=$(cat $DEVPATH/wp-config.php | grep "'DB_NAME', '" | awk '{print $2}' | sed -r "s/[\'|\)|;]//g")
DBUSER=$(cat $DEVPATH/wp-config.php | grep "'DB_USER', '" | awk '{print $2}' | sed -r "s/[\'|\)|;]//g")
DBPASS=$(cat $DEVPATH/wp-config.php | grep "'DB_PASSWORD', '" | awk '{print $2}' | sed -r "s/[\'|\)|;]//g")
DBPASS_FILTERED=$(echo $DBPASS | sed -e 's/[^a-zA-Z0-9,._+@%/-]/\\&/g; 1{$s/^$/""/}; 1!s/^/"/; $!s/$/"/')

echo "Launching $1 to $2 on lovely..."

#read -p "Database name: " DBNAME
read -s -p "Database admin password: " DBROOTPASS
echo ""
read -p "Client admin email: " ADMINEMAIL
echo ""

echo "---------------------"
echo "--- Here we go... ---"
echo "---------------------"


# Set up remote MySQL and copy the site and database to the live server
mysqldump -u root -p"$DBROOTPASS" $DBNAME | ssh gaswirth@lovely "cat > /tmp/$1.sql"

ssh gaswirth@lovely <<-EOF1
	mysql -u root -p"$DBROOTPASS" <<-EOF2
		CREATE DATABASE $DBNAME;
		CREATE USER '$DBUSER'@'localhost' IDENTIFIED BY '$DBPASS';
		GRANT ALL PRIVILEGES ON $DBNAME.* TO '$DBUSER'@'localhost';
		FLUSH PRIVILEGES;
	EOF2
	mysql -u root -p"$DBROOTPASS" $DBNAME < /tmp/$1.sql
	# Remove temporary files
	rm /tmp/$1.sql
EOF1


# Backup the development directory and database
cd $DEVROOT
echo "Backing up..."
sudo rsync -a $1 $1.bak
mysqldump -u root -p"$DBROOTPASS" $DBNAME > $1.prelaunch.sql


# Update Core and Plugins, then run the migrate!
cd $DEVPATH
wp option update admin_email "$ADMINEMAIL"
wp core update
wp plugin update --all
wp search-replace "https://dev.roundhouse-designs.com/$1" "http://$2"
wp search-replace "http://dev.roundhouse-designs.com/$1" "http://$2"

# Copy site files from dev to live
rsync -avze ssh $DEVPATH gaswirth@lovely:/tmp

#Open SSH connection...
ssh -t gaswirth@lovely bash -c "'

# Create and move to the launch directory, then remove the /tmp files
mkdir -p $DOMAINPATH/{public,log}
rsync -a /tmp/$1/* $DOMAINPATH/public
rm -rf /tmp/$1

# Set up Apache to serve new site
cd $APACHEDIR
sudo cp _template.conf $APACHEFILE
sudo sed -i "s/domain\.com/$2/g" $APACHEFILE
sudo sed -i "s/poolname/$1/g" $APACHEFILE
sudo a2ensite $APACHEFILE
sudo service apache2 reload


# Run last WP-CLI actions and set final permissions
cd $DOMAINPATH/public
wp rewrite flush --hard
wp plugin activate w3-total-cache

sudo find wp-content/themes/ -name "*.dead" -exec rm {} \;
sudo chmod 664 *;
sudo find . -type d -exec chmod 774 {} \;
sudo chmod -R 775 wp-content
sudo sed -i "s/\'WP_DEBUG_LOG\', true/\'WP_DEBUG_LOG\', false/i" wp-config.php
sudo sed -i "s/\'WP_MEMORY_LIMIT', \'-1\'/\'WP_MEMORY_LIMIT\', \'96M\'/i" wp-config.php
sudo sed -i "s/\'WP_MAX_MEMORY_LIMIT', \'-1\'/\'WP_MAX_MEMORY_LIMIT\', \'256M\'/i" wp-config.php
sudo mv wp-config.php ../
sudo chown -R www-data:www-data .

echo "Done! Disconnecting..."

'"

echo '---------------------------------'
echo '------ You did it, tiger!! ------'
echo '------ NOW GO CREATE A POOL -----'
echo '---------------------------------'