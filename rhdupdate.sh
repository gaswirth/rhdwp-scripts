#!/bin/bash

#
# DO NOT CALL THIS SCRIPT DIRECTLY. Move to ~/scripts and edit directories to suit server
#

export PATH="/home/gaswirth/npm/bin:/home/gaswirth/.npm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"

for D in /var/www/public_html/*; do
        if [ -d $D ]
        then
                DIR="${D}/public"
                CONT="${DIR}/wp-content"
                echo "SITE: ${D}"
                chown -R www-data:www-data ${CONT} && chmod -R 775 ${CONT}
                sudo -u gaswirth -i -- wp plugin update --all --path=${DIR} --quiet
                sudo -u gaswirth -i -- wp theme update --all --path=${DIR} --quiet
                sudo -u gaswirth -i -- wp core update --path=${DIR} --quiet
                chown -R www-data:www-data ${CONT} && chmod -R 775 ${CONT}
        fi
done
