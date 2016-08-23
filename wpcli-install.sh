#!/bin/bash

_cwd=$PWD

cd /tmp
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar && sudo mv wp-cli.phar /usr/local/bin/wp

# Test it
wp --info

# Back to where you started...
cd $_cwd
