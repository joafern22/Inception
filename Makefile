COMPOSE	= docker compose -f srcs/docker-compose.yml
DATA	= /home/joafern2/data

all: up

up:
	mkdir -p $(DATA)/mariadb $(DATA)/wordpress
	$(COMPOSE) up -d --build

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

re: fclean all

.PHONY: all up down stop start clean fclean re
