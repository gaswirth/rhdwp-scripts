#!/bin/bash

echo "*****************"
echo "** Site basics **"
echo "*****************"

read -p "Site Title: " TITLE
read -p "Site directory/repo name (without 'rhd' prefix): " PROJNAME
REPONAME="rhd-$PROJNAME"
read -p "Theme directory name ('rhd' prefix ok): " THEMEDIR
echo "*****************"
read -p "Database name: " DBNAME
read -p "Database user: " DBUSER
read -s -p "Database password: " DBPASS
echo ""
echo "*****************"
read -p "Branch: " BRANCH
read -n 1 -s -r -p "Please create a '$REPONAME' GitHub repo, then press any key to continue..."
echo ""

echo "*******************"
echo "** Rock and roll **"
echo "******************"

ROOTPATH=/var/www/public_html/
DEVPATHFULL="$ROOTPATH$PROJNAME"
mkdir "$DEVPATHFULL"
cd "$DEVPATHFULL"
pwd

# MySQL Setup
echo "mySQL"
sudo mysql -u root -p << EOF
CREATE DATABASE $DBNAME;
GRANT ALL PRIVILEGES ON $DBNAME.* TO "$DBUSER"@'localhost' IDENTIFIED BY '$DBPASS';
FLUSH PRIVILEGES;
EOF

wp core download && wp core config --dbname="$DBNAME" --dbprefix="rhd_wp_" --dbuser="$DBUSER" --dbpass="$DBPASS" --extra-php << PHP 
// ROUNDHOUSE DESIGNS CUSTOMIZATIONS
define( 'WPLANG', '');
define( 'WP_DEBUG_LOG', true );
define( 'FORCE_SSL_ADMIN', true );
define( 'EMPTY_TRASH_DAYS', 30 );
define( 'WP_MEMORY_LIMIT', '96M' );
define( 'WP_MAX_MEMORY_LIMIT', '256M' );
define( 'WP_AUTO_UPDATE_CORE', true );
PHP

wp core install --url="http://dev.roundhouse-designs.com/${PROJNAME}" --title="$TITLE" --admin_user="nick" --admin_password="H961CxwzdYymwIelIRQm" --admin_email="nick@roundhouse-designs.com"

wp rewrite structure '/%postname%/'
wp rewrite flush --hard

# Clone RHD Hannah and mirror to new repo
cd wp-content/themes
git clone --bare git@github.com:gaswirth/rhdwp-hannah.git
cd rhdwp-hannah.git
git push --mirror git@github.com:gaswirth/"$REPONAME".git
cd ..
rm -rf rhdwp-hannah.git

# Clone new repo and prep for development
if [ -z "$BRANCH" ]
then
	git clone git@github.com:gaswirth/"$REPONAME" "$THEMEDIR"
else
	git clone -b "$BRANCH" git@github.com:gaswirth/"$REPONAME" "$THEMEDIR"
fi

cd "$THEMEDIR"
npm install grunt
npm install --save-dev grunt-contrib-stylus grunt-contrib-watch grunt-contrib-jshint
yarn init -y

# While we're still in wp-content, change SITEBASE placeholders to dev directory name for Stylus vars
# We'll also change the main site name in style.css and generate some base stylesheets
sed -i 's/SITEBASE/"$PROJNAME"/g' assets/stylus/global.styl
sed -ri "s/Theme Name: (.*?)/Theme Name: RHD $TITLE/" style.css
sed -ri "s/Description: (.*?)/Description: A custom WordPress theme for $TITLE by Roundhouse Designs/" style.css
grunt stylus:dev

# Activate the theme, and create the primary nav menu
wp theme activate "$THEMEDIR"
wp menu create "Site Navigation"
wp menu location assign "Site Navigation" primary
cd "$DEVPATHFULL"

# Install WPMUDEV + Dashboard
cp -rv /home/gaswirth/resources/plugins/wpmudev-updates wp-content/plugins/
cp -rv /home/gaswirth/resources/plugins/google-analytics-async wp-content/plugins/
cp -rv /home/gaswirth/resources/plugins/wp-smush-pro wp-content/plugins/
cp -rv /home/gaswirth/resources/plugins/wp-hummingbird wp-content/plugins
cp -rv /home/gaswirth/resources/plugins/soliloquy wp-content/plugins
cp -rv /home/gaswirth/resources/plugins/ninja-forms-mail-chimp wp-content/plugins
cp -rv /home/gaswirth/resources/plugins/ninja-forms-layout-styles wp-content/plugins
cp -rv /home/gaswirth/resources/plugins/social-pug wp-content/plugins

# Set up mu-plugins directory and install plugins
mkdir wp-content/mu-plugins
git clone git@github.com:gaswirth/rhdwp-mu-loader.git wp-content/mu-plugins
git clone git@github.com:gaswirth/rhdwp-social-icons.git wp-content/mu-plugins/rhd-social-icons

# Get rid of built-in themes and unwanted plugins
rm -rf `find wp-content/themes -type d -name 'twenty*'`
wp plugin delete hello

# Install and activate plugins
wp plugin install ninja-forms ajax-thumbnail-rebuild intuitive-custom-post-order enable-media-replace tinymce-advanced force-strong-passwords mobble --activate

# Install plugins but don't activate
# (Nothing yet...)

# Update and activate private plugins
wp plugin activate wpmudev-updates wp-smush-pro google-analytics-async
wp plugin update --all --quiet

# Finish user creation
wp user create ryan ryan@roundhouse-designs.com --role="administrator" --first_name="Ryan" --last_name="Foy" --send-email
wp user update nick --first_name="Nick" --last_name="Gaswirth"
wp user update nick ryan --user_url="https://roundhouse-designs.com"

# Set final permissions
cd "$DEVPATHFULL"
sudo chmod -R 664 *
sudo find . -type d -exec chmod 775 {} \;
sudo chown -R www-data:www-data .

echo '******------------'
echo '------ You did it, tiger!! ------'
echo '******------------'
