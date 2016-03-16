#!/bin/bash

echo "---------------------"
echo "---- Site basics ----"
echo "---------------------"

read -p "Site Title: " TITLE
read -p "Dev directory: " DEVDIR
read -p "Theme directory name: " THEMESLUG
read -p "Database name: " DBNAME
read -p "Database user: " DBUSER
read -s -p "Database password: " DBPASS
echo ""
read -s -p "MySQL Admin password: " DBROOTPASS
echo ""
read -p "Theme (scrolly/hannah/slideways): " THEME
read -p "Branch: " BRANCH

echo "---------------------"
echo "--- Here we go... ---"
echo "---------------------"

DIR=$(pwd)
DEVPATH=/var/www/public_html/dev.roundhouse-designs.com/public/"$DEVDIR"
mkdir "$DEVDIR"
cd "$DEVDIR"

# MySQL Setup
mysql -u root -p"$DBROOTPASS" << EOF
CREATE DATABASE $DBNAME;
CREATE USER $DBUSER;
GRANT ALL PRIVILEGES ON $DBNAME.* TO "$DBUSER"@'localhost' IDENTIFIED BY '$DBPASS';
FLUSH PRIVILEGES;
EOF

wp core download && wp core config --dbname="$DBNAME" --dbprefix="rhd_wp_" --dbuser="$DBUSER" --dbpass="$DBPASS" --extra-php << PHP 
define( 'WPLANG', '');
define ( 'WP_DEBUG', true );
define ( 'WP_DEBUG_LOG', true );
define( 'FORCE_SSL_ADMIN', true );
\$_SERVER['HTTPS']='on';
PHP

wp core install --url="http://dev.roundhouse-designs.com/${DEVDIR}" --title="$TITLE" --admin_user="nick" --admin_password="H961CxwzdYymwIelIRQm" --admin_email="nick@roundhouse-designs.com"
wp rewrite structure '/%postname%/'

# Finish user creation
wp user create ryan ryan@roundhouse-designs.com --role="administrator" --first_name="Ryan" --last_name="Foy" --send-email
wp user update nick --first_name="Nick" --last_name="Gaswirth"
wp user update nick ryan --user_url="https://roundhouse-designs.com"

# Install RHD theme
if [ -z "$BRANCH" ]
then
	git clone git@github.com:gaswirth/rhdwp-"$THEME".git wp-content/themes/rhd
else
	git clone -b "$BRANCH" git@github.com:gaswirth/rhdwp-"$THEME".git wp-content/themes/rhd
fi

# Perform theme directory actions
cd wp-content/themes/rhd
bower install jquery Slidebars packery fitvids
mv crossdomain.xml.movetoroot "$DEVPATH"/crossdomain.xml
rm README.md

# While we're still in wp-content, change SITEBASE placeholders to dev directory name for our Stylus vars
# We'll also change the main site name in style.css
# then generate some base stylesheets
sed -i 's/SITEBASE/"$DEVDIR"/g' stylus/partials/_global.styl
sed -ri "s/Theme Name: (.*?)/Theme Name: RHD $TITLE/g" style.css
grunt stylus:dev

# Rename the theme directory, activate the theme, and create the primary nav menu
cd .. && mv rhd "$THEMESLUG"
wp theme activate "$THEMESLUG"
wp menu create "Site Navigation"
wp menu location assign "Site Navigation" primary
cd "$DEVPATH"

# Install WPMUDEV + Dashboard
cp -rv /home/gaswirth/resources/plugins/wpmudev/wpmudev-updates wp-content/plugins/
cp -rv /home/gaswirth/resources/plugins/wpmudev/google-analytics-async wp-content/plugins/
cp -rv /home/gaswirth/resources/plugins/wpmudev/wp-smush-pro wp-content/plugins/
cp -rv /home/gaswirth/resources/plugins/wpmudev/wpmu-dev-seo wp-content/plugins
cp -rv /home/gaswirth/resources/plugins/soliloquy wp-content/plugins
cp -rv /home/gaswirth/resources/plugins/ninja-forms-mailchimp wp-content/plugins

# Set up mu-plugins directory
mkdir wp-content/mu-plugins
cp -r /home/gaswirth/resources/rhd-wp-setup/mu-load.php wp-content/mu-plugins

# Get rid of built-in themes
rm -rf `find wp-content/themes -type d -name 'twenty*'`

# Install and activate plugins
wp plugin install ninja-forms ajax-thumbnail-rebuild intuitive-custom-post-order enable-media-replace wp-social-likes wp-retina-2x tinymce-advanced velvet-blues-update-urls force-strong-passwords cloudflare --activate

# Install plugins but don't activate
wp plugin install akismet w3-total-cache wp-social-likes gotmls rest-api

# Update and activate private plugins
wp plugin activate wpmudev-updates wpmu-dev-seo wp-smush-pro google-analytics-async 
wp plugin update --all --quiet

# Set final permissions
cd "$DEVPATH"
sudo find . -type f -exec chmod 664 {} \;
sudo find . -type d -exec chmod 774 {} \;
sudo chmod -R 775 wp-content
sudo chown -R www-data:www-data .

echo '---------------------------------'
echo '------ You did it, tiger!! ------'
echo '---------------------------------'