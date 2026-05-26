.PHONY: help build up down logs restart ps clean dev test

COMPOSE ?= docker compose

help:
	@echo "EconTrainer · Docker Compose (Project 1)"
	@echo ""
	@echo "make build    — собрать образы"
	@echo "make up       — запустить весь стек в фоне"
	@echo "make down     — остановить и удалить контейнеры"
	@echo "make logs     — логи всех сервисов (Ctrl+C для выхода)"
	@echo "make restart  — пересоздать сервисы"
	@echo "make ps       — статус сервисов"
	@echo "make clean    — down + удалить volumes (СНЕСЁТ ДАННЫЕ БД)"
	@echo "make dev      — up + tail логов в foreground"
	@echo "make test     — smoke-test: curl главной"

build:
	$(COMPOSE) build --pull

up:
	@test -f .env || (echo "Create .env from .env.example first" && exit 1)
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f --tail=200

restart:
	$(COMPOSE) restart

ps:
	$(COMPOSE) ps

clean:
	$(COMPOSE) down -v

dev:
	@test -f .env || cp .env.example .env
	$(COMPOSE) up

test:
	@curl -sS -o /dev/null -w "HTTP %{http_code} (%{size_download} bytes, %{time_total}s)\n" http://localhost:$${HTTP_PORT:-80}/ || \
	  (echo "App is not running. Run 'make up' first."; exit 1)
	@curl -sS http://localhost:$${HTTP_PORT:-80}/healthz | grep -q ok && echo "/healthz OK"
