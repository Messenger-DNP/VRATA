up:
	docker compose up --build

upd:
	docker compose up --build -d

down:
	docker compose down

down-v:
	docker compose down -v

build:
	docker compose build

logs:
	docker compose logs

logs-f:
	docker compose logs -f

ps:
	docker compose ps

restart:
	docker compose restart
