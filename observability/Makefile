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
