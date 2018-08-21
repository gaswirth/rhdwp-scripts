#!/bin/bash

echo "*****************"
echo "** Site basics **"
echo "*****************"

read -p "Site Title: " TITLE
read -p "Site root (no namespace prefixes): " PROJNAME
read -p "Child Theme name: " THEMENAME
echo "*****************"
read -p "Database name: " DBNAME
read -p "Database user: " DBUSER
read -s -p "Database password: " DBPASS
echo ""
echo "*****************"
read -p "GitHub repository name: " REPONAME
read -n 1 -s -r -p "Please create a '$REPONAME' GitHub repository, then press any key to continue..."
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
wp core install --url="http://dev.roundhouse-designs.com/${PROJNAME}" --title="$TITLE" --admin_user="nick" --admin_email="nick@roundhouse-designs.com"

# Generate .htaccess and set rewrite structure
wp rewrite structure '/%postname%/'
wp rewrite flush --hard

## THEME
# Retrieve RHDWP base theme
echo "Installing RHDWP Base Theme..."
cd "$THEMESDIR"
rm -rf twenty*

# Download the RHDWP base
git clone git@github.com:gaswirth/rhdwp.git rhdwp

# Create the child theme
wp scaffold child-theme "$THEMESLUG" --parent_theme=rhdwp --author="Roundhouse Designs" --author_uri=https://roundhouse-designs.com --theme_uri=https://github.com/gaswirth/"$REPONAME".git --activate
cd "$THEMESDIR"/"$THEMESLUG"
sed -i "s/$THEMESLUG/$THEMENAME/gI" style.css
cp "$THEMESDIR"/rhdwp/Gruntfile.js .
cp "$THEMESDIR"/rhdwp/.gitignore .
mkdir css
mkdir stylus

# Yarn setup
yarn config set init-license GPL-2.0
yarn config set init-main Gruntfile.js
yarn config set init-version 1.0
yarn init --yes 
yarn add grunt grunt-contrib-stylus grunt-contrib-watch grunt-contrib-jshint livereload-js --dev
yarn install

# Set up GitHub repository
echo "Initializing GitHub repository..."
git init
git add *
git commit -m "Initial commit"
git remote add origin git@github.com:gaswirth/"$REPONAME".git
git push -u origin master

# Create the primary nav menu, and add the Sample Page for display
# wp menu create "Main Navigation"
# wp menu location assign "Site Navigation" primary
# wp menu item add-post 2 --title="Sample"

# Make sure to "exit" back to the root dir.
cd "$SITEROOT"

## PLUGINS
echo "Installing plugins..."

# Install WPMUDEV + Dashboard
cp -rv /home/gaswirth/resources/plugins/wpmudev-updates wp-content/plugins/
cp -rv /home/gaswirth/resources/plugins/wp-smush-pro wp-content/plugins/
cp -rv /home/gaswirth/resources/plugins/wp-hummingbird wp-content/plugins
cp -rv /home/gaswirth/resource/plugins/wp-defender wp-content/plugins
cp -rv /home/gaswirth/resources/plugins/soliloquy wp-content/plugins

# Install and activate plugins
wp plugin install ajax-thumbnail-rebuild enable-media-replace force-strong-passwords social-warfare schema --activate

# Plugins for install only
# (None)

# Update and activate private plugins
echo "Installing private plugins..."
wp plugin activate wpmudev-updates wp-smush-pro
wp plugin update --all --quiet

# Finish user creation
echo "Create users..."
wp user create ryan ryan@roundhouse-designs.com --role="administrator" --first_name="Ryan" --last_name="Foy" --send-email
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