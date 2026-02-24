.PHONY: help build up down logs ps clean network

help:
	@echo "Available commands:"
	@echo "  make network    - Create the observability Docker network"
	@echo "  make build      - Build all Docker images"
	@echo "  make up         - Start all containers"
	@echo "  make down       - Stop all containers"
	@echo "  make logs       - View logs (follow mode)"
	@echo "  make ps         - Show container status"
	@echo "  make clean      - Remove containers and volumes"
	@echo "  make cachet     - Build and start only Cachet"

network:
	docker network create observability || true

build: network
	docker compose build

up: network
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f

ps:
	docker compose ps

clean: down
	docker compose down -v
	rm -rf /data/cachet

cachet: network
	docker compose build cachet
	docker compose up -d cachet-db cachet

cachet-logs:
	docker compose logs -f cachet
