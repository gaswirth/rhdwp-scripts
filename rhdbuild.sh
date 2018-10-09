#!/bin/bash

echo "*****************"
echo "** Site basics **"
echo "*****************"

read -p "Site Title: " TITLE
read -p "Site root (no namespace prefixes): " PROJNAME
read -p "Database name: " DBNAME
read -p "Database user: " DBUSER
read -s -p "Database password: " DBPASS
echo ""
echo "*****************"
read -p "GitHub repository name: " REPONAME
read -n 1 -s -r -p "Please create a '$REPONAME' GitHub repository, then press any key to continue..."
echo ""
echo "*****************"
read -p "Send WordPress emails Y/N? (Default: N)" SENDEMAILS
echo ""
echo "*******************"
echo "** Rock and roll **"
echo "******************"

# Vars
ROOTPATH=/var/www/public_html/
SITEROOT="$ROOTPATH$PROJNAME"
CONTENTDIR="$SITEROOT"/wp-content/
THEMESDIR="$CONTENTDIR"/themes
THEMESLUG=${THEMENAME// /-} && THEMESLUG=${THEMESLUG,,}

# MYSQL SETUP
echo "mySQL setup..."
mysql << EOF
CREATE DATABASE $DBNAME;
GRANT ALL PRIVILEGES ON $DBNAME.* TO "$DBUSER"@'localhost' IDENTIFIED BY '$DBPASS';
FLUSH PRIVILEGES;
EOF

## SITE FILES
mkdir "$SITEROOT"

## WORDPRESS
# Set up and install with wp-cli
echo "WordPress setup..."
cd "$SITEROOT"
wp core download && wp core config --dbname="$DBNAME" --dbprefix="rhd_wp_" --dbuser="$DBUSER" --dbpass="$DBPASS" --extra-php << PHP 
/* Added by Roundhouse Designs */
define( 'WPLANG', '');
define( 'WP_DEBUG_LOG', true );
define( 'FORCE_SSL_ADMIN', true );
define( 'EMPTY_TRASH_DAYS', 30 );
define( 'WP_MEMORY_LIMIT', '64M' );
define( 'WP_MAX_MEMORY_LIMIT', '96M' );
define( 'WP_AUTO_UPDATE_CORE', true );
/* End Roundhouse Designs */
PHP

# Complete WP install
echo "Installing WordPress..."
wp core install --url="http://dev.roundhouse-designs.com/${PROJNAME}" --title="$TITLE" --admin_user="nick" --admin_email="nick@roundhouse-designs.com" --skip-email

# Generate .htaccess and set rewrite structure
wp rewrite structure '/%postname%/'
wp rewrite flush --hard

## THEME
# Retrieve RHDWP base theme
echo "Installing RHDWP Base Theme..."
cd "$THEMESDIR"
rm -rf twenty*

# Download the RHDWP base
git clone git@github.com:gaswirth/rhdwp.git rhdwp && cd rhdwp

# NPM setup
npm config set init-license GPL-2.0
npm config set init-version 1.0.0
npm config set init-author-name "Nick Gaswirth"
npm config set init-author-email "admin@roundhouse-designs.com"
npm config set init-author-url "https://roundhouse-designs.com"
npm add --save-dev grunt grunt-contrib-stylus grunt-contrib-watch grunt-contrib-jshint livereload-js
npm init --yes
npm install

# Set up GitHub repository
echo "Initializing GitHub repository..."
git init
git add *
git commit -m "Initial commit"
git remote add origin git@github.com:gaswirth/"$REPONAME".git
git push -u origin master

# Make sure to "exit" back to the root dir, and then activate the theme.
cd "$SITEROOT"
wp theme activate rhdwp

## PLUGINS
echo "Installing plugins..."

# Install WPMUDEV + Dashboard
cp -rv /home/gaswirth/resources/plugins/wpmudev-updates wp-content/plugins/
cp -rv /home/gaswirth/resources/plugins/wp-smush-pro wp-content/plugins/
cp -rv /home/gaswirth/resources/plugins/wp-hummingbird wp-content/plugins
cp -rv /home/gaswirth/resource/plugins/wp-defender wp-content/plugins
cp -rv /home/gaswirth/resources/plugins/soliloquy wp-content/plugins

# Install and activate plugins
wp plugin install ajax-thumbnail-rebuild enable-media-replace force-strong-passwords social-warfare gutenberg --activate

# Plugins for install only
# (None)

# Update and activate private plugins
echo "Installing private plugins..."
wp plugin activate wpmudev-updates wp-smush-pro
wp plugin update --all --quiet

# Finish user creation
echo "Create users..."
if [ "$SENDEMAILS" = "y" ] || [ "$SENDEMAILS" = "Y" ]; then
	wp user create ryan ryan@roundhouse-designs.com --role="administrator" --first_name="Ryan" --last_name="Foy" --send-email
else
	wp user create ryan ryan@roundhouse-designs.com --role="administrator" --first_name="Ryan" --last_name="Foy"
fi

wp user update nick --first_name="Nick" --last_name="Gaswirth"
wp user update nick ryan --user_url="https://roundhouse-designs.com"

# Set final permissions
echo "Finalizing..."
cd "$SITEROOT"
sudo chmod -R 664 .
sudo find . -type d -name ".git" -prune -o -type d -exec chmod 775 {} \;
sudo chown -R www-data:www-data .

echo "**********************"
echo "** Good work, tiger **"
echo "**********************"
