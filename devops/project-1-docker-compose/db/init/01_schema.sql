-- EconTrainer: применение базовой схемы для бэкенда.
-- Источник: ../../../../database/schema.sql из дипломного репозитория.
-- В production миграции запускаются отдельным workflow.

-- Создаём роль app_chat для приложения.
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_chat') THEN
    CREATE ROLE app_chat LOGIN PASSWORD 'change-me';
  END IF;
END $$;

GRANT CONNECT ON DATABASE econtrainer TO app_chat;
GRANT USAGE ON SCHEMA public TO app_chat;
