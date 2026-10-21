# User documentation

This document explains how to use and check the Inception stack. For setting
it up from scratch, see `DEV_DOC.md`.

## Services provided

The stack serves a WordPress website at `https://joafern2.42.fr`. It runs three
services, each in its own container:

| Service | What it does | Reachable from outside |
|---|---|---|
| `nginx` | Receives every visitor over HTTPS (port 443) and forwards PHP requests to WordPress | Yes, port 443 only |
| `wordpress` | Runs the WordPress site with php-fpm | No |
| `mariadb` | Stores the site's content: posts, pages, users, settings | No |

NGINX is the only way in. The site accepts HTTPS only, with TLS 1.2 or 1.3;
plain HTTP on port 80 is not available.

## Starting and stopping

Run these commands from the repository root:

| Command | Effect |
|---|---|
| `make` | Start the stack (on the first run, also sets everything up) |
| `make stop` | Stop the containers, keeping them and all data |
| `make start` | Start stopped containers again |
| `make down` | Stop and remove the containers; all data is kept |

The containers restart automatically after a crash or a reboot of the machine,
unless they were stopped on purpose with `make stop` or `make down`.

`make fclean` deletes everything, including the site's content and the
passwords. Use it only when a complete reset is wanted.

## Accessing the website

- **Website:** `https://joafern2.42.fr`
- **Administration panel:** `https://joafern2.42.fr/wp-admin`

The certificate is self-signed, so the browser shows a security warning the
first time. Choose "Advanced", then "Proceed" (or "Accept the risk"). The
connection is still encrypted.

To open the site from a computer other than the virtual machine, that computer
needs this line in its hosts file (on Windows,
`C:\Windows\System32\drivers\etc\hosts`, edited as administrator):

```
127.0.0.1    joafern2.42.fr
```

## Credentials

Usernames are in `srcs/.env`. Passwords are in the `secrets/` folder, which is
generated on the first `make` and never stored in Git.

| Account | Username | Password |
|---|---|---|
| WordPress administrator | `WP_ADMIN_USER` in `srcs/.env` | Line 1 of `secrets/credentials.txt` |
| WordPress second user (author) | `WP_USER` in `srcs/.env` | Line 2 of `secrets/credentials.txt` |
| Database user used by WordPress | `MYSQL_USER` in `srcs/.env` | `secrets/db_password.txt` |
| Database root | `root` | `secrets/db_root_password.txt` |

To read a password:

```bash
cat secrets/credentials.txt
```

WordPress passwords can be changed from the administration panel (Users >
Profile). Do not edit or delete the files in `secrets/` while the stack has
data: the database keeps the passwords it was created with, and the files
would no longer match. To get new passwords, run `make fclean`, then `make`.

## Checking that everything works

**Are the containers running?**

```bash
docker compose -f srcs/docker-compose.yml ps
```

All three should show "Up". Only `nginx` should list a published port
(`443`).

**Does the site answer?**

```bash
curl -k https://joafern2.42.fr
```

This prints the home page's HTML. (`-k` accepts the self-signed certificate.)

**Is a service reporting errors?**

```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

**Are both WordPress users present?**

```bash
docker exec -u www-data wordpress wp user list
```

**Is the database reachable?**

```bash
docker exec -it mariadb mariadb -u wpuser -p wordpress -e "SHOW TABLES;"
```

Enter the password from `secrets/db_password.txt`. The output lists the
WordPress tables, whose names start with `wp_`.