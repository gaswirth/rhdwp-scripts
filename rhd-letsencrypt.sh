#!/bin/bash

read -p "Webroot: " WEBROOT
read -p "Domain: " DOMAIN

sudo letsencrypt certonly --webroot --webroot-path "$WEBROOT" --renew-by-default --email admin@roundhouse-designs.com --text --agree-tos -d "$DOMAIN"
