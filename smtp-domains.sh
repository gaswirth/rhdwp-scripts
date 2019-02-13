#!/bin/bash

set -x

# Do not process these folders in /srv/www/
exclude=(
        'nginx-proxy'
        'portainer'
        'traefik'
)

for d in /srv/www/*; do
	virtual_host=${d##*/}
	exclude_match=0
	if [ -d "$d" ]; then
		for domain in "${exclude[@]}"; do
			if [ "$domain" = "${virtual_host}" ]; then
			exclude_match=1
			echo "SKIP ${virtual_host}"
			break
		fi
	done
	if [ "$exclude_match" = 0 ]; then
		echo "Processing $virtual_host"
		# Check for saved CLOUDFLARE_API_KEY and MAILGUN_API_KEY
		if [ -r "/home/gaswirth/.rhdwp-docker" ]; then
			source "/home/gaswirth/.rhdwp-docker"
		fi
			
		mailgun_mail_host="mail.${virtual_host}"
		wordpress_smtp_login="postmaster@mail.${virtual_host}"
		wordpress_smtp_password=$(openssl rand -base64 24 | sed 's/.$//')
		
		# Check if mailgun domain already exists
		mailgun_domain_response=$(curl -s --user "api:${MAILGUN_API_KEY}" \
									-G https://api.mailgun.net/v3/domains/"${mailgun_mail_host}")
		
		message=$(echo "${mailgun_domain_response}" | jq -r '.message')
		if [[ "${message}" =~ "not found" ]]; then
			# Create domain if check returns 'not found' and get a new response
			mailgun_domain_response=$(curl -s --user "api:${MAILGUN_API_KEY}" \
										-X POST https://api.mailgun.net/v3/domains \
										-F name="${mailgun_mail_host}")
		fi
		
		# create mailgun user
		curl -s --user "api:${MAILGUN_API_KEY}" \
			"https://api.mailgun.net/v3/domains/${mailgun_mail_host}/credentials" \
			-F login="${wordpress_smtp_login}" \
			-F password="${wordpress_smtp_password}"
		
		# GET ZONE ID
		cf_zone=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${virtual_host}&status=active&match=all" \
			-H "X-Auth-Email: nick@roundhouse-designs.com" \
			-H "X-Auth-Key: ${CLOUDFLARE_API_KEY}" \
			-H "Content-Type: application/json")
		cf_zone_id=$(echo "${cf_zone}" | jq -r ".result[0].id")
		
		# CREATE DNS ENTRIES
		# Domain verification records
		for row in $(echo "${mailgun_domain_response}" | jq -r '.sending_dns_records[] | @base64'); do
			_jq() {
				echo "${row}" | base64 --decode | jq -r "${1}"
			}
			
			rec_name=$(_jq '.name')
			rec_type=$(_jq '.record_type')
			rec_value=$(_jq '.value')
			
			# Skip adding Mailgun CNAME (tracking) entry to CloudFlare
			if [ "${rec_type}" != "CNAME" ]; then
				curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cf_zone_id}/dns_records" \
					-H "X-Auth-Email: nick@roundhouse-designs.com" \
					-H "X-Auth-Key: ${CLOUDFLARE_API_KEY}" \
					-H "Content-Type: application/json" \
					--data '{"type":'\""${rec_type}\""',"name":'\""${rec_name}\""',"content":'\""${rec_value}\""',"ttl":1,"proxied":false}'
			fi
		done
		
		# Domain MX records
		for row in $(echo "${mailgun_domain_response}" | jq -r '.receiving_dns_records[] | @base64'); do
			_jq() {
				echo "${row}" | base64 --decode | jq -r "${1}"
			}
			
			rec_type=$(_jq '.record_type')
			rec_priority=$(_jq '.priority')
			rec_value=$(_jq '.value')
		
			curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cf_zone_id}/dns_records" \
				-H "X-Auth-Email: nick@roundhouse-designs.com" \
				-H "X-Auth-Key: ${CLOUDFLARE_API_KEY}" \
				-H "Content-Type: application/json" \
				--data '{"type":'\""${rec_type}\""',"name":'\""${virtual_host}\""',"content":'\""${rec_value}\""',"priority":'"${rec_priority}"',"ttl":1,"proxied":false}'
		done
	fi
done