# set starting point
FROM debian:bookworm

# download the lastest list of packages
# install the DB skipping optional packages
# delete the package list
RUN apt-get update \
    && apt-get install -y --no-install-recommends mariadb-server \
    && rm -rf /var/lib/apt/lists/*

# create the service user refered by the config and the script
RUN useradd --system joafern2

# copy the config into the image
# copy the startup script
# give permission to execute the script
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY tools/init.sh /usr/local/bin/init.sh
RUN chmod +x /usr/local/bin/init.sh

# record the listening port of the service
EXPOSE 3306

# set the runnig program when a container starts from this image
ENTRYPOINT ["init.sh"]