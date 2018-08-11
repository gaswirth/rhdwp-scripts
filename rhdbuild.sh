#!/bin/bash

echo "*****************"
echo "** Site basics **"
echo "*****************"

read -p "Site Title: " TITLE
read -p "Site root (no namespace prefixes): " PROJNAME
read -p "Theme directory name (namespace prefixes ok): " THEMEDIR
echo "*****************"
read -p "Database name: " DBNAME
read -p "Database user: " DBUSER
read -s -p "Database password: " DBPASS
echo ""
echo "*****************"
read -p "GitHub repository name: " REPONAME
read -p "Branch: " BRANCH
read -n 1 -s -r -p "Please create a '$REPONAME' GitHub repo or '$BRANCH' remote branch, then press any key to continue..."
echo ""

echo "*******************"
echo "** Rock and roll **"
echo "******************"

# MYSQL SETUP
echo "mySQL setup..."
mysql << EOF
CREATE DATABASE $DBNAME;
GRANT ALL PRIVILEGES ON $DBNAME.* TO "$DBUSER"@'localhost' IDENTIFIED BY '$DBPASS';
FLUSH PRIVILEGES;
EOF

## SITE FILES
ROOTPATH=/var/www/public_html/
SITEROOT="$ROOTPATH$PROJNAME"
mkdir "$SITEROOT"

## WORDPRESS
# Set up and install with wp-cli
echo "WordPress setup..."
cd "$SITEROOT"
wp core download --skip-content && wp core config --dbname="$DBNAME" --dbprefix="rhd_wp_" --dbuser="$DBUSER" --dbpass="$DBPASS" --extra-php << PHP 
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

# Clone RHD Hannah and mirror to new repo
echo "GitHub repository setup..."
mkdir wp-content && cd wp-content
if [ -z "$BRANCH" ]
then
	git clone -b master --single-branch git@github.com:gaswirth/rhdwp-hannah.git rhdtemp
	mv rhdtemp/themes .
	mv rhdtemp/mu-plugins .
	git init
	git remote add origin git@github.com:gaswirth/"$REPONAME".git
else
	git clone -b "$BRANCH" git@github.com:gaswirth/rhdwp-hannah.git rhdtemp
	mv rhdtemp/themes .
	mv rhdtemp/mu-plugins .
fi
rm -rf rhdtemp

# Complete WP install
echo "Installing WordPress..."
wp core install --url="http://dev.roundhouse-designs.com/${PROJNAME}" --title="$TITLE" --admin_user="nick" --admin_password="H961CxwzdYymwIelIRQm" --admin_email="nick@roundhouse-designs.com"

# Generate .htaccess and set rewrite structure
wp rewrite flush --hard
wp rewrite structure '/%postname%/'

## THEME
# Initialize Yarn and install Grunt + dependencies
echo "Theme setup..."
mv themes/rhd-hannah themes/"$THEMEDIR" && cd themes/"$THEMEDIR"
yarn init
sed -ri "s/\"name\": \"rhdwp-hannah\"/\"name\": \"$REPONAME\"/" package.json
sed -ri "s/rhdwp-hannah.git/$REPONAME/" package.json
yarn add grunt grunt-contrib-stylus grunt-contrib-watch grunt-contrib-jshint
yarn install

# While we're still in the theme dir, change SITEBASE placeholders to dev directory name for Stylus vars
# We'll also change the main site name in style.css and generate some base stylesheets
echo "Customize labels..."
sed -i 's/SITEBASE/"$PROJNAME"/g' assets/stylus/global.styl
sed -ri "s/Theme Name: (.*?)/Theme Name: RHD $TITLE/" style.css
sed -ri "s/Description: (.*?)/Description: A custom WordPress theme for $TITLE by Roundhouse Designs/" style.css
grunt stylus:dev

# Activate the theme, create the primary nav menu, and add the Sample Page for display
wp theme activate "$THEMEDIR"
wp menu create "Site Navigation"
wp menu location assign "Site Navigation" primary
wp menu item add-post 2 --title="Sample"

# Make sure to "exit" back to the root dir.
cd "$SITEROOT"

## PLUGINS
echo "Installing plugins..."
mkdir wp-content/plugins

# Install WPMUDEV + Dashboard
cp -rv /home/gaswirth/resources/plugins/wpmudev-updates wp-content/plugins/
cp -rv /home/gaswirth/resources/plugins/wp-smush-pro wp-content/plugins/
cp -rv /home/gaswirth/resources/plugins/wp-hummingbird wp-content/plugins
cp -rv /home/gaswirth/resource/plugins/wp-defender wp-content/plugins
cp -rv /home/gaswirth/resources/plugins/soliloquy wp-content/plugins

# Install and activate plugins
wp plugin install ajax-thumbnail-rebuild enable-media-replace tinymce-advanced force-strong-passwords social-warfare schema --activate

# Plugins for install only
# (None)

# Update and activate private plugins
echo "Installing private plugins..."
wp plugin activate wpmudev-updates wp-smush-pro
wp plugin update --all --quiet

# Add installed plugins to the repo, commit changes, and push to remote
cd "$SITEROOT"/wp-content
git add *
git commit -m "Initial commit"
git push -u origin master

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
