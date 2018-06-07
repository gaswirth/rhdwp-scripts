#!/bin/bash
hostname=`hostname`

export B2_ACCOUNT_ID="4bc42f267688"
export B2_ACCOUNT_KEY="00244196b19d8095255129a248f5e2eff1fd383a52"
export RESTIC_REPOSITORY="b2:linode-${hostname}"
export RESTIC_PASSWORD_FILE="/home/gaswirth/scripts/.restic"

# MySQL
if [ -f ~/.my.cnf ]
then
  mysqldump --opt --all-databases | restic backup --tag mysql --stdin
else
  echo "No mysql config file. Skipping..."
fi

# Files
restic backup --tag site-files /var/www/ --exclude="*.log" --exclude="log/*" --exclude="cache/*"
