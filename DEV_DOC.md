# Developer documentation

This document explains how to set up, build, run and maintain the Inception
stack. For everyday use (access, credentials, health checks), see
`USER_DOC.md`.

## 1. Setting up the environment from scratch

### Prerequisites

- A Linux virtual machine (developed on Debian 12) with a user named after the
  42 login (`joafern2`), since the data lives in `/home/joafern2/data`
- Docker Engine and the Docker Compose plugin, installed from Docker's own apt
  repository
- The user in the `docker` group (`sudo usermod -aG docker $USER`, then log in
  again)
- `git`, `make`, `openssl` and `sudo`

Check the tools with:

```bash
docker --version
docker compose version
make --version
```

### Getting the code

```bash
git clone <repository URL> inception
cd inception
```

### Configuration files

| File | Purpose | In Git |
|---|---|---|
| `srcs/.env` | Non-secret settings: domain, database name and user, site title, WordPress usernames and emails | Yes |
| `srcs/docker-compose.yml` | Services, volumes, network and secrets | Yes |
| `srcs/requirements/<service>/conf/` | Configuration copied into each image | Yes |
| `secrets/*.txt` | Passwords | No (generated) |

Edit `srcs/.env` before the first `make` to change any setting. Constraints:
the administrator's username must not contain "admin", and the two email
addresses must differ. WordPress stores these values in its database at
installation, so changing them later requires `make re`.

### Secrets

The Makefile generates the three password files on the first `make`, with
`openssl rand -hex 16`, only if they do not already exist:

| File | Contents | Used by |
|---|---|---|
| `secrets/db_root_password.txt` | MariaDB root password | `mariadb` |
| `secrets/db_password.txt` | Password of the database user WordPress uses | `mariadb`, `wordpress` |
| `secrets/credentials.txt` | Line 1: WordPress administrator; line 2: second user | `wordpress` |

Compose mounts each secret only into the services that list it, as a
read-only file at `/run/secrets/<name>` (without the `.txt`). The secrets and
the data must always be kept or deleted together: the database stores the
passwords on its first start, so new password files would not match an
existing database.

## 2. Building and launching

### With the Makefile

Run from the repository root:

```bash
make
```

`make` (the `all` rule) performs, in order:

1. `hosts`: adds `127.0.0.1 joafern2.42.fr` to `/etc/hosts` if missing (asks
   for the `sudo` password only when it writes);
2. creates any missing secret file;
3. creates `/home/joafern2/data/mariadb` and `/home/joafern2/data/wordpress`;
4. runs `docker compose -f srcs/docker-compose.yml up -d --build`.

| Rule | Effect |
|---|---|
| `make` / `make all` | Full setup and start |
| `make up` | Secrets, data folders, build and start (no hosts check) |
| `make stop` / `make start` | Stop or start the existing containers |
| `make down` | Remove the containers and the network |
| `make clean` | `down`, then `docker system prune -f` |
| `make fclean` | Remove containers, images, volumes, `/home/joafern2/data` and `secrets/` |
| `make re` | `fclean`, then `all` |

### With Docker Compose directly

The Compose file is in `srcs/`, so every command needs `-f`:

```bash
docker compose -f srcs/docker-compose.yml up -d --build
docker compose -f srcs/docker-compose.yml down
```

`--build` rebuilds any image whose Dockerfile, config or script changed.
Without it, Compose reuses the existing images.

### Start order

Compose starts `mariadb`, then `wordpress`, then `nginx` (`depends_on`).
This only orders the starts; it does not wait for readiness. The WordPress
script therefore waits for MariaDB itself, pinging it up to 30 times before
installing.

### What happens on the first start

- **MariaDB** (`init.sh`): if `/data/mariadb/<database>` does not exist,
  initialises the data directory, creates the database and its user, and sets
  the root password. Then runs `mariadbd` as PID 1.
- **WordPress** (`setup.sh`): if `wp-config.php` does not exist, downloads
  WordPress with WP-CLI, writes `wp-config.php`, installs the site and creates
  both users. Then gives the files to `www-data` and runs `php-fpm8.2 -F` as
  PID 1.
- **NGINX** (`start.sh`): if no certificate exists in the container, generates
  a self-signed one for `DOMAIN_NAME`. Then runs NGINX in the foreground as
  PID 1.

On later starts, the setup steps are skipped and existing data is reused.

## 3. Managing containers and volumes

### Containers

```bash
docker compose -f srcs/docker-compose.yml ps    # state of the project's containers
docker logs -f <container>                      # follow a container's output
docker exec -it <container> bash                # open a shell inside it
docker restart <container>                      # restart one service
```

Container names are `nginx`, `wordpress` and `mariadb`.

Useful commands inside the services:

```bash
docker exec -u www-data wordpress wp user list
docker exec -u www-data wordpress wp option get siteurl
docker exec -it mariadb mariadb -u root -p
docker exec nginx nginx -t                      # check the NGINX configuration
```

`WORKDIR /var/www/html` in the WordPress image lets WP-CLI find the
installation without `--path`.

### Images

```bash
docker images                                   # list images
docker image prune                              # remove dangling images left by rebuilds
```

Images are disposable: any of them can be deleted and rebuilt from the
repository with `make`.

### Volumes and network

```bash
docker volume ls
docker volume inspect srcs_mariadb_data
docker network inspect srcs_inception
```

Compose prefixes names with the project name, which defaults to the folder
holding the Compose file (`srcs`).

## 4. Where the data is stored and how it persists

| Volume | Mounted at (container) | Stored at (VM) | Contents |
|---|---|---|---|
| `mariadb_data` | `/data/mariadb` in `mariadb` | `/home/joafern2/data/mariadb` | The database |
| `wordpress_data` | `/var/www/html` in `wordpress` and `nginx` | `/home/joafern2/data/wordpress` | WordPress files, `wp-config.php`, uploads |

Both are named volumes using the `local` driver, with `driver_opts`
(`type: none`, `o: bind`, `device: <path>`) placing their data in
`/home/joafern2/data`. The files exist once, on the VM; containers see the same
files at their mount paths.

### What survives what

| Action | Containers | Images | Data |
|---|---|---|---|
| Container crash, VM reboot | Restarted automatically | Kept | Kept |
| `make stop` / `make down` | Stopped / removed | Kept | Kept |
| `make clean` | Removed | Kept | Kept |
| `make fclean` | Removed | Removed | Deleted |

Removing a volume (`docker compose down --volumes`) only deletes Docker's
record of it. Because the data lives in a chosen folder, `make fclean` also
deletes `/home/joafern2/data` explicitly.

### File ownership

The data files belong to the users inside the containers (the MariaDB
service user and `www-data`, UID 33), not to the VM user. Linux stores owners
as numeric UIDs, and those UIDs do not match the VM login (UID 1000), so
deleting the data from the VM requires `sudo`. This is why `make fclean` runs
`sudo rm -rf`.

### Resetting the site

To reinstall WordPress and the database from scratch, keeping nothing:

```bash
make re
```

This generates new passwords; read them again from `secrets/` afterwards.