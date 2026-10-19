LOGIN	= joafern2
DOMAIN	= $(LOGIN).42.fr
DATA	= /home/$(LOGIN)/data
COMPOSE	= docker compose -f srcs/docker-compose.yml
DATA	= /home/joafern2/data
SECRETS	= secrets/db_root_password.txt secrets/db_password.txt secrets/credentials.txt

all: hosts up

hosts:
	grep -qF "$(DOMAIN)" /etc/hosts || echo "127.0.0.1 $(DOMAIN)" | sudo tee -a /etc/hosts > /dev/null

up: srcs/.env $(SECRETS)
	mkdir -p $(DATA)/mariadb $(DATA)/wordpress
	$(COMPOSE) up -d --build

srcs/.env:
	cp srcs/.env.example srcs/.env

secrets/db_root_password.txt secrets/db_password.txt:
	mkdir -p secrets
	openssl rand -hex 16 > $@

secrets/credentials.txt:
	mkdir -p secrets
	openssl rand -hex 16 > $@
	openssl rand -hex 16 >> $@

down:
	$(COMPOSE) down

stop:
	$(COMPOSE) stop

start:
	$(COMPOSE) start

clean: down
	docker system prune -f

fclean:
	$(COMPOSE) down --rmi all --volumes
	sudo rm -rf $(DATA)
	rm -rf secrets
	rm -f srcs/.env

re: fclean all

.PHONY: all up down stop start clean fclean re
