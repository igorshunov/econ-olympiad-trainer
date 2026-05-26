# EconTrainer

Адаптивный тренажёр для подготовки к олимпиадам по экономике.

Граф тем с пререквизитами + адаптивный движок подбора задач: после каждой задачи
пользователь отмечает «решил / не смог / слишком просто / слишком сложно», и
следующая задача автоматически выбирается из соседней (upstream/downstream)
темы графа знаний.

**Дипломный проект, учебная практика УП.02 + УП.11, 2025-2026 уч.г.**
Автор: Горшунов Игорь Станиславович.

## Стек

- Frontend: vanilla HTML/CSS/JS, [Cytoscape.js](https://js.cytoscape.org/) для графа знаний
- БД: PostgreSQL 16 (схема см. в `database/`)
- Хранилище в демо-версии: `localStorage`

## Структура

- `webapp/` — фронтенд (deployable на GitHub Pages)
- `database/` — DDL, seed, демонстрационные SQL-запросы, ER-диаграмма
- `docs/` — описание дипломного проекта, use-case диаграмма, скриншоты

## Демо

После деплоя на GitHub Pages приложение доступно по адресу:
`https://<user>.github.io/econ-olympiad-trainer/`

## Локальный запуск

```bash
# Фронтенд (на любом порту)
cd webapp && python3 -m http.server 8765

# БД (через Docker)
docker run -d --name pg-econ -e POSTGRES_PASSWORD=econ -e POSTGRES_DB=econtrainer -p 5432:5432 postgres:16-alpine
docker cp database/schema.sql pg-econ:/tmp/ && docker exec -e PGPASSWORD=econ pg-econ psql -U postgres -d econtrainer -f /tmp/schema.sql
docker cp database/seed.sql pg-econ:/tmp/   && docker exec -e PGPASSWORD=econ pg-econ psql -U postgres -d econtrainer -f /tmp/seed.sql
```

## Лицензия

MIT.
