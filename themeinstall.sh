#!/bin/bash

set -x

echo "*****************"
echo "** Theme Setup **"
echo "*****************"
read -p "Site Title: " title
read -p "Project Name (theme directory): " projectname
read -n 1 -s -r -p "Please create a '${projectname}' GitHub repo, then press any key to continue..."
echo
echo "*********************"
echo "*** Cool bruh thx ***"
echo "*********************"

# Make sure we're in the project root
if [ "${PWD##*/}" != "themes" ]; then
	echo "Please run this script from the themes folder in which you want to install rhdwp."
	exit 1
fi

# Clone RHD Hannah and mirror to new repo
git clone -b master git@github.com:gaswirth/rhdwp.git rhdwp
cd rhdwp
git push --mirror "git@github.com:gaswirth/${projectname}.git"
cd ..
rm -rf rhdwp
git clone "git@github.com:gaswirth/${projectname}.git" "${projectname}"

## THEME
# Initialize NPM and install Grunt + dependencies
cd "${projectname}"
sed -ri "s/\"name\": \"rhdwp-hannah\"/\"name\": \"${projectname}\"/" package.json
sed -ri "s/rhdwp-hannah.git/${projectname}/" package.json
yarn init
yarn add grunt grunt-contrib-stylus grunt-contrib-watch grunt-contrib-jshint
yarn install

# While we're still in the theme dir, change SITEBASE placeholders to dev directory name for Stylus vars
# We'll also change the main site name in style.css and generate some base stylesheets
sed -i 's/SITEBASE/"${projectname}"/g' assets/stylus/global.styl
sed -ri "s/Theme Name: (.*?)/Theme Name: RHD $title/" style.css
sed -ri "s/Description: (.*?)/Description: A custom WordPress theme for $title by Roundhouse Designs/" style.css
grunt stylus:compile

## Go to project root
cd ../../../../

# Activate the theme, create the primary nav menu, and add the Sample Page for display
docker-compose run --rm wp-cli theme activate "${projectname}"
docker-compose run --rm wp-cli menu create "Site Navigation"
docker-compose run --rm wp-cli menu location assign "Site Navigation" primary
docker-compose run --rm wp-cli menu item add-post 2 --title="Sample"

# Make sure to "exit" back to the root dir.
cd "$SITEROOT"

# Update and activate private plugins
docker-compose run --rm wp-cli plugin activate wpmudev-updates
docker-compose run --rm wp-cli plugin update --all --quiet

# Uncle Ryney
docker-compose run --rm wp-cli user create ryan ryan@roundhouse-designs.com --role="administrator" --first_name="Ryan" --last_name="Foy" --send-email

echo "**********************"
echo "** Good work, tiger **"
echo "**********************"