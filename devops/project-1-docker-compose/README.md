# Проект №1 — Упаковка в Docker Compose

Курс: **DevOps для программистов** (Хекслет колледж).
Студент: Горшунов Игорь Станиславович, группа 15.ИСиП.23.О-ЗФ.С.1.ХК.

Приложение для упаковки — **EconTrainer**, фронтенд из дипломного проекта
(адаптивный тренажёр по олимпиадам по экономике, см. [репозиторий](https://github.com/igorshunov/econ-olympiad-trainer)).

## Цель

Упаковать веб-приложение в воспроизводимый набор Docker-контейнеров,
готовый к деплою на любой Linux-хост одной командой.

## Что внутри стека

| Сервис | Образ | Назначение |
|--------|-------|------------|
| `econtrainer` | собирается из `Dockerfile` (multi-stage: node-build → nginx-alpine) | Статика EconTrainer + nginx |
| `db` | `postgres:16-alpine` | БД для будущего бэкенда |
| `proxy` | `caddy:2.10-alpine` | reverse-proxy с авто-HTTPS |

Все три сервиса связаны через внутреннюю сеть `internal`; снаружи доступен
только `proxy` (порты 80/443). БД и приложение не публикуются на host.

## Принципы 12-factor, которые здесь соблюдены

- **Codebase**: один git-репозиторий → один deploy.
- **Dependencies** в `Dockerfile` (node-tooling для build, nginx для runtime — больше ничего на host не нужно).
- **Config**: через `.env` (`POSTGRES_PASSWORD`, `HTTP_PORT` и т.д.), `.env.example` версионируется.
- **Backing services**: БД и proxy — взаимозаменяемые ресурсы по URL.
- **Build, release, run**: стадия build (Dockerfile) отделена от run.
- **Processes**: stateless фронт.
- **Port binding**: приложение слушает 80 внутри контейнера, наружу — только через proxy.
- **Concurrency**: масштабирование через `docker compose up --scale econtrainer=N`.
- **Disposability**: graceful `nginx -s quit` через docker stop.
- **Dev/prod parity**: `make dev` поднимает то же самое, что `make up`, отличается только `.env`.
- **Logs**: stdout/stderr контейнеров.
- **Admin processes**: одноразовые скрипты — `docker compose run --rm db psql ...`.

## Быстрый старт

```bash
# 1. Подготовка
cp .env.example .env            # отредактировать POSTGRES_PASSWORD
make build

# 2. Запуск
make up
make test                       # HTTP 200, /healthz OK

# 3. Открыть в браузере
open http://localhost/

# 4. Логи
make logs

# 5. Остановка
make down
```

## Структура

```
project-1-docker-compose/
├── Dockerfile                  — multi-stage: node-build → nginx runtime
├── docker-compose.yml          — 3 сервиса + 1 сеть + 3 volume
├── .env.example                — пример переменных окружения
├── Makefile                    — удобные команды build/up/down/logs/test
├── app/                        — исходники EconTrainer (HTML/CSS/JS)
├── nginx/default.conf          — server-блок: gzip, security headers, cache, cleanUrls
├── proxy/Caddyfile             — конфиг reverse-proxy
└── db/init/01_schema.sql       — init-скрипт БД (создание роли app_chat)
```

## Проверка

После `make up` ожидаемо:

```
$ docker compose ps
NAME                 STATUS         PORTS
econtrainer          Up (healthy)
econtrainer-db       Up (healthy)
econtrainer-proxy    Up             0.0.0.0:80->80/tcp

$ make test
HTTP 200 (2543 bytes, 0.024s)
/healthz OK
```

## Возможные расширения

- Регистрация образа в реестре (GHCR) и CI через GitHub Actions;
- Подключение бэкенда (FastAPI) как отдельный сервис;
- Метрики Prometheus через nginx-exporter и postgres-exporter;
- Хранение секретов через Docker Swarm secrets / Vault.

## Лицензия

MIT.
