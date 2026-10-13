FROM debian:bookworm

# install php services: executable, command line version, extension for DB access
# provide mariadb-admin required by the script
# add verification of secure authetications (HTTPS/TLS)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        php8.2-fpm php8.2-cli php8.2-mysql \
        mariadb-client \
        curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# install WP-CLI and make it executable
RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

# replace debian defaullt pool with mine
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

# document the php-fpm port publishes nothing
EXPOSE 9000

# runs the script as PID 1 when container starts
ENTRYPOINT ["setup.sh"]