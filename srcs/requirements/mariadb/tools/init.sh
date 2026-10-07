#!/bin/sh

# abort the script if any command fails
set -e

# make the data and DB directories
# give ownership of those directories to my user
mkdir -p  /inception/mariadb /data/mariadb
chown -R joafern2: /inception/mariadb /data/mariadb

# if the wordpress DB wasn't built
#   get the passwords
#   if internal mariaDB database wasn't built (stores users and permissions)
#       create that internal structure - throws away the output
#   start the DB in setup mode
#   create the DB, add users and permissions
if [ ! -d "/data/mariadb/${MYSQL_DATABASE}" ]; then
    DB_ROOT_PASSWORD=$(cat /inception/secrets/db_root_password)
    DB_PASSWORD=$(cat /inception/secrets/db_password)

    if [ ! -d /data/db/mysql ]; then
        mariadb-install-db --user=joafern2 --datadir=/data/mariadb > /dev/null
    fi
    mariadbd --user=joafern2 --bootstrap <<EOF
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_DATABASE}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF
fi

# execute the server
exec mariadbd --user=joafern2