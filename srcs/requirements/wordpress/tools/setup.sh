#!/bin/sh
# run with sh and stop at the first failling command
set -e

# create a folder where php-fpm writes a file holding its process ID
mkdir -p /run/php

# read the DB password
DB_PASSWORD=$(cat /run/secrets/db_password)

# check if MariaDB container has been set
tries=0
until mariadb-admin ping --host=mariadb --user"${MYSQL_USER}" --password="${DB_PASSWORD}" --silent; do
    tries=$((tries + 1))
    if [ "$tries" -ge 30 ]; then
        echo "MariaDB not reachable after 30 attempts" >&2
        exit 1
    fi
    sleep 1
done

# create wordpress DB file 
if [ ! -f /var/www/html/wp-config.php ]; then
    WP_ADMIN_PASSWORD=$(sed -n '1p' /run/secrets/credentials)
    WP_USER_PASSWORD=$(sed -n '2p' /run/secrets/credentials)

# dowloand and unpack wordpress
    if [ ! -f /var/www/html/wp-load.php ]; then
        wp core download --path=/var/www/html --allow-root
    fi

# enter the DB name, user, password and host
    wp config create --path=/var/www/html --allow-root \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="{DB_PASSWORD}" \
        --dbhost=mariadb:3306

# enter the title and administartor, then install
    wp core install --path=/var/www/html --allow-root \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email

# create the ordinary user 
    wp user create "${WP_USER}" "${WP_USER_EMAIL}" --path=/var/www/html --allow-root \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}"
fi

# give ownership of every wordpress file
chown -R www-data:www-data /var/www/html

# execute php fastCGI process manager
exec php-fpm8.2 -F