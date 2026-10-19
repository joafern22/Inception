#!/bin/sh
set -e

# create the TLS certificate 
if [ ! -f /etc/nginx/ssl/inception.crt ]; then

# make a folder to store the pair of keys
    mkdir -p /etc/nginx/ssl

# create both keys
    openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
        -keyout /etc/nginx/ssl/inception.key \
        -out /etc/nginx/ssl/inception.crt  \
        -subj "/C=PT/L=Lisboa/O=42/CN=${DOMAIN_NAME}"
fi

exec nginx -g "daemon off;"