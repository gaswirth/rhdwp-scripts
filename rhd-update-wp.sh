#!/bin/bash
export PATH="/home/gaswirth/npm/bin:/home/gaswirth/.npm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"

for d in /var/www/public_html/*; do
	if [ -d $d ] && [ $d != dev.roundhouse-designs.com ]
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

for d in /var/www/public_html/dev.roundhouse-designs.com/public/*; do
        if [ -d $d ]
	then
		path="$d"
        	wp plugin update --all --path=$path --quiet && wp theme update --all --path=$path --quiet && wp core update --path=$path --quiet
	fi
done
