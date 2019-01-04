#!/bin/bash

for D in /var/www/public_html/*; do
	DIR="${D##*/}"
	if [ ! -d "$DIR" ]; then
		git clone git@github.com:gaswirth/rhdwp-docker.git "$DIR"
	fi
done
