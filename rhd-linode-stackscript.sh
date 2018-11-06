#!/bin/bash
# <UDF name="hostname" label="Hostname" />
# <UDF name="userpassword" label="User password" />
# <UDF name="sharedenv" label="Shared environment?" example="Y/N" default="N" />
# <UDF name="db_password" Label="MySQL root Password" />
# <UDF name="db_name" Label="Create Database" default="" example="Optionally create this database" />
# <UDF name="db_user" Label="Create MySQL User" default="" example="Optionally create this user" />
# <UDF name="db_user_password" Label="Create MySQL User Password" default="" example="User's password" />
# <UDF name="domain" Label="Site Domain" example="Example: domain.com" default="default" />
# <UDF name="interactive" Label="Interactive dpkg?" example="Y/N (default: N)" default="" />
# <UDF name="php_ver" Label="PHP Version" example="7.1 (default: 7.1)" default="7.1" />

source <ssinclude StackScriptID="1">

function rhd_initial_setup {
	apt update -y
	
	# Essential installs
	apt install -y postfix git ufw mailutils screen software-properties-common wget letsencrypt less man-db clamav clamav-daemon memcached sasl2-bin
	
	# System Updates (non-interactive)
	if [ "$INTERACTIVE" = "y" ] || [ "$INTERACTIVE" = "Y" ]; then
		apt upgrade
		apt dist-upgrade
	else
		export DEBIAN_FRONTEND=noninteractive
		apt upgrade -y
		apt -o Dpkg::Options::="--force-confold" -o Dpkg::Options::="--force-confdef" dist-upgrade -y 
	fi
	
	# Ondrej PHP repo
	add-apt-repository ppa:ondrej/php -y
	apt update -y
	
	# Git setup
	git config --global user.email "nick@roundhouse-designs.com"
	git config --global user.name "Nick Gaswirth"
	git config --global push.default simple
	
	# NPM
	curl -sL https://deb.nodesource.com/setup_8.x | sudo bash -
	apt install nodejs -y
	npm install -g grunt-cli
	
	# Services
	echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
	echo "postfix postfix/mailname string $FQDN" | debconf-set-selections
	
	# Firewall
	ufw default deny incoming
	ufw default allow outgoing
	ufw allow ssh
	ufw allow http
	ufw allow https
	ufw enable
}


function rhd_users_setup {
	# Users
	# Set up gaswirth and foy users
	apt install -y sudo
	adduser gaswirth --disabled-password --gecos ""
	echo -e "$USERPASSWORD\n$USERPASSWORD" | passwd gaswirth
	usermod -aG sudo gaswirth
	
	adduser foy --disabled-password --gecos ""
	echo "foy:$(cat /dev/urandom | tr -cd [:graph:] | head -c 12)" | chpasswd
	usermod -aG sudo foy
	
	# Install user pubkeys
	# Generate SSH keys for gaswirth
	mkdir {/home/gaswirth/.ssh,/home/foy/.ssh}
	touch {/home/gaswirth/.ssh/authorized_keys,/home/foy/.ssh/authorized_keys}
	chmod 700 /home/gaswirth/.ssh /home/foy/.ssh
	chmod 600 /home/gaswirth/.ssh/authorized_keys /home/foy/.ssh/authorized_keys
	chown -R gaswirth:gaswirth /home/gaswirth/.ssh
	chown -R foy:foy /home/foy/.ssh
	sudo -u gaswirth ssh-keygen -f /home/gaswirth/.ssh/id_rsa -N ''
	
	#gaswirth
	echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC79KWiV0WjBJV8c6AgJnonh12jlVr//3e23of+ADCfgNMasIB8UT9H+xM1zeBh8GmzsrrI4FfiGhhvawa6gyFgbJsSReKWJbsoqFYzUYTDulECsO/iTO438lYIdu4Jsobm+1UsNOX6p3u2zXCrfj1ItLUSGT/dFwTizZIXmktrrg8icW3uFcPieVUqC1qVGsznIgYPDUhPIDLeEELzU87fOfy49YuTZ/M10a4Y8zIv9klzno27RZm90OTA4eqZ1VA+7soWo3TREzhY3X/ZQHC2kdhaseAgUdPfm1hxFg7Cc+Czs6+lAwcA1WhPMAdBKteq5ovbAvphOpQIuVVPkQ+1 gaswirth@Frankengassy.local" >> /home/gaswirth/.ssh/authorized_keys
	echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDbTWzq9yXe8A52N/HzINynxX+miY1zLoh2yTKXxzaJ/OdZGcpMFXWTdy8X+RHtOBIzrOD8oNeQGnEZVzKOYnJQBM1UhUztuJkjn2BM5KCh4LhKOhdn6XjrF8WfKN3P/rcjG0E9IREMKDvtQvdFIqaC2FNkKnVDtan5l3ga1493pckImDO1+E+qwfc3n/XsXj9kHXJ4di9CQ7Y8FI/ODvRq2m+/cZea9RZqHSPYjzhoH2/ol9w5ihLYb9L6sEEaGHn/Xr03bS5paAGV6QG4l2+4UuefLfrgUv4oYx1VVHwejrg26ickU9tuOFCvrOq4eQq4VTCkmEzYtFf/TdhCg33/ gaswirth@Gassybook.local" >> /home/gaswirth/.ssh/authorized_keys
	
	#foy
	echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDTvprX8q2H13YwUtbtaIiBk6MT8is8cb4IJJitZQ3DrQ4IpmLulepxKFPdAqzUE2wxCfU8xmXzC2uIq/VGp02dbVOzT2bHyi9XAJTGX4s7hsVyACPXeSHW30dpdHYrLPbEBLx9TY7ODg/sZ/wLb7OAACglLHlxn7/KkRfWyS2XpCWjCzpLK2koC2NpvAFqyue18cBZ37Jm/fIArPiiYxV3JCzAfkStAf14iv4UjRZ0UyJqN2XCYML+Lplo2ltvSffRYTuFxrzszJNkfLuKVx5Gagx7V4P/+GYKpBLAmHpIKTQjEoIqxcA7kNfGOBIAWK21z9ZzlRQGnhO6kqXOPhur foy@Ryan-Foys-Macbook-Pro-2.local" > /home/foy/.ssh/authorized_keys
	echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDnr84P+XxFziw1jz+UrJjxIp+1ORttNkJxUtmnsBIhyMJkub7OZwCfHsZzjp1rIsTx8lP0TPIR7yl77QZ0e/O9v6Jtc/De2UkI0vaoahjSmt6MEfezVuz+V0zh0VLBZ2GKzBEU2sNW8KqkVvgyeIASDLFMd57jJDk0UxPsTaShIbYDvzPrXId44z9J6r3BrmzFVFrt3CmF1LBaxNasyOXN46MURzQ/EPWAO8r99yvHrsNGmOGrC5HFdS5FXP2fgFttj9laERieQ4UAj5jSGyl7+mEtLaPP2tGDpHTsRCjMHM6O9JV62d8kuf9MPGnKuDQM+4Ifo3zlUv/9hCvFT9Y1 foy@Ryan-Foys-iMac.local" >> /home/foy/.ssh/authorized_keys
	
	# Kill SSH root login
	ssh_disable_root
}


function rhd_runme_script {
	cd /home/gaswirth
	wget https://raw.githubusercontent.com/gaswirth/rhdwp-scripts/forked-repos/runme.sh
	chmod +x runme.sh
}


function rhd_cron_setup {
	# Update
	git clone https://github.com/gaswirth/rhdwp-wp_helper.git /usr/local/bin/rhd_wp_helper
	chown -R www-data:www-data /usr/local/bin/rhd_wp_helper
	chmod 774 /usr/local/bin/rhd_wp_helper/*.sh
	
	if [ "$SHAREDENV" = "y" ] || [ "$SHAREDENV" = "Y" ]; then	
		HELPER="run_wp_helper.sh"
	else
		HELPER="wp_helper.sh"
	fi
	
	# Install Restic (backups)
	cd /tmp
	wget https://github.com/restic/restic/releases/download/v0.9.0/restic_0.9.0_linux_amd64.bz2
	bunzip2 restic_0.9.0_linux_amd64.bz2
	mv restic_0.9.0_linux_amd64 /usr/local/bin/restic
	chmod 700 /usr/local/bin/restic
	chown gaswirth:gaswirth /usr/local/bin/restic
	
	# mysqldump passwordless for gaswirth and root (for restic backup script)
	cat > /home/gaswirth/.my.cnf <<- EOF
		[mysqldump]
		user=root
		password="$DB_PASSWORD"
	EOF
	chown gaswirth:gaswirth /home/gaswirth/.my.cnf
	chmod 600 /home/gaswirth/.my.cnf
	cp /home/gaswirth/.my.cnf /root/.my.cnf
	chown root:root /root/.my.cnf
	
	# Cron jobs
	# root
	cat > /var/spool/cron/crontabs/root <<- EOF
		0 0 1,15 * * letsencrypt renew --agree-tos --m admin@roundhouse-designs.com
		0 */6 * * * bash /home/gaswirth/scripts/restic-backup.sh >/dev/null 2>&1
	EOF
	
	# www-data
	cat > /var/spool/cron/crontabs/www-data <<- EOF
		30 6 * * * /usr/local/bin/rhd_wp_helper/$HELPER
	EOF
	
	rhd_runme_script
}


function rhd_environment_setup {
	# Apache2
	apt install -y apache2
	a2dissite 000-default.conf
	rhd_apache_tune 40
	mkdir /var/www/{public,log}
	rm -rf /var/www/html
	usermod -aG www-data gaswirth
	
	# Apache2 AllowOverride All on /var/www
	cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.bak
	sed '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride All/AllowOverride None/' /etc/apache2/apache2.conf
	
	# PHP + MySQL
	apt update
	apt install -y php"${PHP_VER}" libapache2-mod-php"${PHP_VER}" php"${PHP_VER}"-mysql php"${PHP_VER}"-memcached php"${PHP_VER}"-json php"${PHP_VER}"-mcrypt php"${PHP_VER}"-mbstring php"${PHP_VER}"-xml php"${PHP_VER}"-xmlrpc php"${PHP_VER}"-curl php"${PHP_VER}"-gd php"${PHP_VER}"-imagick
	
	# MySQL
	if [ ! -z "$DB_PASSWORD" ]; then
		mysql_install "$DB_PASSWORD" && mysql_tune 40
		
		if [ ! -z "$DB_USER" ] || [ ! -z "$DB_USER_PASSWORD" ]; then
			mysql_create_database "$DB_PASSWORD" "$DB_NAME"
			mysql_create_user "$DB_PASSWORD" "$DB_USER" "$DB_USER_PASSWORD"
			mysql_grant_user "$DB_PASSWORD" "$DB_USER" "$DB_NAME"
		fi
	fi
	
	# MySQL customizations
	cp /etc/mysql/mysql.conf.d/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf.bak
	sed -i -e 's/query_cache_limit/#query_cache_limit/' /etc/mysql/mysql.conf.d/mysqld.cnf
	sed -i -e 's/query_cache_size/#query_cache_size/' /etc/mysql/mysql.conf.d/mysqld.cnf
	echo "" >> /etc/mysql/mysql.conf.d/mysqld.cnf
	echo "# RHD" >> /etc/mysql/mysql.conf.d/mysqld.cnf
	echo "query_cache_size = 0" >> /etc/mysql/mysql.conf.d/mysqld.cnf
    echo "query_cache_type =0" >> /etc/mysql/mysql.conf.d/mysqld.cnf
    echo "query_cache_limit = 16M" >> /etc/mysql/mysql.conf.d/mysqld.cnf
    echo "join_buffer_size = 512K" >> /etc/mysql/mysql.conf.d/mysqld.cnf
    echo "tmp_table_size = 32M" >> /etc/mysql/mysql.conf.d/mysqld.cnf
    echo "max_heap_table_size = 32M" >> /etc/mysql/mysql.conf.d/mysqld.cnf
    echo "innodb_log_file_size = 16M" >> /etc/mysql/mysql.conf.d/mysqld.cnf
	
	# Node.js 8.x + Yarn
	curl -sL https://deb.nodesource.com/setup_8.x | bash -
	curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
	echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
	apt update && apt install -y nodejs yarn
	yarn global add grunt-cli
	
	# WP-CLI
	curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
	chmod 774 wp-cli.phar
	chown www-data:www-data wp-cli.phar
	mv wp-cli.phar /usr/local/bin/wp
}

function rhd_apache_tune {
	# Tunes Apache's memory to use the percentage of RAM you specify, defaulting to 70%
	
	# $1 - the percent of system memory to allocate towards Apache
	
	if [ ! -n "$1" ];
		then PERCENT=70
		else PERCENT="$1"
	fi
	
	apt -y install apache2-mpm-prefork libapache2-modsecurity
	a2enmod expires ssl rewrite headers security2
	PERPROCMEM=15 # the amount of memory in MB each apache process is likely to utilize
	MEM=$(grep MemTotal /proc/meminfo | awk '{ print int($2/1024) }') # how much memory in MB this system has
	MAXCLIENTS=$((MEM*PERCENT/100/PERPROCMEM)) # calculate MaxClients
	MAXCLIENTS=${MAXCLIENTS/.*} # cast to an integer
	sed -i -e "s/\(^[ \t]*MaxClients[ \t]*\)[0-9]*/\1$MAXCLIENTS/" /etc/apache2/apache2.conf
}


function rhd_vhost_setup {
	if [ ! -z "$DOMAIN" ]; then
	
		#VirtualHost
		if [ -e "/etc/apache2/sites-available/"$DOMAIN".conf" ]; then
			echo "/etc/apache2/sites-available/"$DOMAIN".conf already exists"
		else
			echo "# domain: $DOMAIN" > /etc/apache2/sites-available/"$DOMAIN".conf
			echo "# public: /var/www/public/" >> /etc/apache2/sites-available/"$DOMAIN".conf
			echo "" >> /etc/apache2/sites-available/"$DOMAIN".conf
			echo "<VirtualHost *:80>" >> /etc/apache2/sites-available/"$DOMAIN".conf
			echo "	ServerName $HOSTNAME" >> /etc/apache2/sites-available/"$DOMAIN".conf
			echo "	ServerAlias www.$HOSTNAME" >> /etc/apache2/sites-available/"$DOMAIN".conf
			echo "	DirectoryIndex index.html index.php" >> /etc/apache2/sites-available/"$DOMAIN".conf
			echo "	DocumentRoot /var/www/public" >> /etc/apache2/sites-available/"$DOMAIN".conf
			echo "	LogLevel warn" >> /etc/apache2/sites-available/"$DOMAIN".conf
			echo "	ErrorLog /var/www/log/error.log" >> /etc/apache2/sites-available/"$DOMAIN".conf
			echo "  CustomLog /var/www/log/access.log combined" >> /etc/apache2/sites-available/"$DOMAIN".conf
			echo "</VirtualHost>" >> /etc/apache2/sites-available/"$DOMAIN".conf
			echo "" >> /etc/apache2/sites-available/"$DOMAIN".conf
			echo "<VirtualHost *:443>" >> /etc/apache2/sites-available/"$DOMAIN".conf
			echo "  ServerName $HOSTNAME" >> /etc/apache2/sites-available/"$DOMAIN".conf
			echo "  ServerAlias www.$HOSTNAME" >> /etc/apache2/sites-available/"$DOMAIN".conf
			echo "  DirectoryIndex index.html index.php" >> /etc/apache2/sites-available/"$DOMAIN".conf
			echo "  DocumentRoot /var/www/public" >> /etc/apache2/sites-available/"$DOMAIN".conf
			echo "	LogLevel warn" >> /etc/apache2/sites-available/"$DOMAIN".conf
			echo "	ErrorLog /var/www/log/error.log" >> /etc/apache2/sites-available/"$DOMAIN".conf
			echo "	CustomLog /var/www/log/acess.log combined" >> /etc/apache2/sites-available/"$DOMAIN".conf
			echo "" >> /etc/apache2/sites-available/"$DOMAIN".conf
			echo "	# SSLEngine On" >> /etc/apache2/sites-available/"$DOMAIN".conf
			echo "	# SSLCertificateFile /etc/letsencrypt/live/$HOSTNAME/fullchain.pem" >> /etc/apache2/sites-available/"$DOMAIN".conf
			echo "	# SSLCertificateKeyFile /etc/letsencrypt/live/$HOSTNAME/privkey.pem" >> /etc/apache2/sites-available/"$DOMAIN".conf
			echo "</VirtualHost>" >> /etc/apache2/sites-available/"$DOMAIN".conf
		fi
		a2ensite "$DOMAIN".conf
	
	fi
}


function rhd_goodstuff {
	# apt cleanup
	apt autoclean -y
	apt autoremove -y

	# iTerm Shell Integration (macOS)
	curl -L https://iterm2.com/misc/install_shell_integration.sh | bash
	
	# Ensure proper permissions, just in case I fucked something up...
	chown gaswirth:gaswirth /home/gaswirth
	chown foy:foy /home/foy
	
	# Restart services
	systemctl restart apache2 

	# Nick's Aliases
	echo "alias a2restart='sudo systemctl restart apache2.service'" >> /home/gaswirth/.bash_aliases
	echo "alias a2reload='sudo systemctl reload apache2.service'" >> /home/gaswirth/.bash_aliases
	echo "alias update='sudo apt update && sudo apt upgrade --show-upgraded --assume-yes'" >> /home/gaswirth/.bash_aliases
	echo "alias perms='sudo chown -R www-data:www-data . && sudo chmod -R 664 * && sudo find . -type d -exec sudo chmod 775 {} \;'" >> /home/gaswirth/.bash_aliases
	echo "alias a2buddy='curl -sL https://raw.githubusercontent.com/richardforth/apache2buddy/master/apache2buddy.pl | sudo perl'" >> /home/gaswirth/.bash_aliases

	# `rhd` shared/private setup
	if [ "$SHAREDENV" = "y" ] || [ "$SHAREDENV" = "Y" ]; then
		echo "alias rhd='cd /var/www/public_html'" >> /home/gaswirth/.bash_aliases
	else
		echo "alias rhd='cd /var/www/public'" >> /home/gaswirth/.bash_aliases
	fi

	chown gaswirth:gaswirth .bash_aliases
}

##################
# Start Script
##################
IP=$(system_primary_ip)
IPV6=$(ifconfig eth0 | awk '/inet6 addr: .+\/64 Scope:Global/{print $3}' | cut -d'/' -f 1)
FQDN="$HOSTNAME.roundhouse-designs.com"

# System setup
hostnamectl set-hostname "$HOSTNAME"
echo "$IP	$FQDN	$HOSTNAME" >> /etc/hosts
echo "$IPV6	$FQDN	$HOSTNAME" >> /etc/hosts

# Roll it out
rhd_initial_setup
rhd_users_setup
rhd_environment_setup
rhd_cron_setup
rhd_vhost_setup
rhd_goodstuff