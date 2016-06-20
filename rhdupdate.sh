#!/bin/bash
export PATH="/home/gaswirth/npm/bin:/home/gaswirth/.npm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"

for d in /home/joanna/public_html/*; do
	if [ -d $d ]
	then
		path="$d/public"
		echo "SITE: $d"
		sudo -u gaswirth -i -- wp plugin update --all --path=$path --quiet
		sudo -u gaswirth -i -- wp theme update --all --path=$path --quiet
		sudo -u gaswirth -i -- wp core update --path=$path --quiet
		chown -R www-data:www-data $path/wp-content
		chmod -R 775 $path/wp-content
	fi
done
