#!/bin/bash
set -e

# $1: main site directory (contains public/ and log/)
if [ -z "$1" ]; then
	echo "No directory supplied."
	exit 1
else
	dir="${1%/}"
fi


wpconfig_get_db_name() {
        # Extract wp-config.php vars. Capture echo as return value.
        local x
        x=$(grep "define(\s*'DB_NAME'" "$dir/public/wp-config.php")
        x=${x#*,*[\'|\"]}
        x=${x%[\'|\"]*}
        echo "${x}"
}

sudo rsync -avze ssh --exclude="*.log" "$dir/public/" gaswirth@bertha:/tmp/"$dir"

# ensure wp-config.php is in the right place...
if [ ! -f "$dir/public/wp-config.php" ]; then
	if  [ -f "$dir/wp-config.php" ]; then
		mv "$dir/wp-config.php" "$dir/public/wp-config.php"
	else
		echo "wp-config.php error. Please check manually and try again."
		exit 1
	fi
fi

db_name=$(wpconfig_get_db_name)
mysqldump --add-drop-table "$db_name" | ssh gaswirth@bertha "cat > /tmp/${db_name}.sql"
echo "Done."
