-- ============================================================================
-- EconTrainer — схема базы данных адаптивного тренажёра по олимпиадам
-- по экономике. Целевая СУБД: PostgreSQL 14+. Совместима с SQLite (с минимальными
-- правками: см. блок в конце файла). Подготовлено в рамках УП.11.
-- ============================================================================

-- Чистая инициализация при разработке
DROP TABLE IF EXISTS attempts        CASCADE;
DROP TABLE IF EXISTS user_mastery    CASCADE;
DROP TABLE IF EXISTS task_topics     CASCADE;
DROP TABLE IF EXISTS tasks           CASCADE;
DROP TABLE IF EXISTS topic_prereqs   CASCADE;
DROP TABLE IF EXISTS topics          CASCADE;
DROP TABLE IF EXISTS sources         CASCADE;
DROP TABLE IF EXISTS users           CASCADE;

-- ============================================================================
-- 1. Пользователи
-- ============================================================================
CREATE TABLE users (
    user_id        SERIAL       PRIMARY KEY,
    email          VARCHAR(255) NOT NULL UNIQUE,
    password_hash  VARCHAR(255) NOT NULL,
    display_name   VARCHAR(120) NOT NULL,
    role           VARCHAR(20)  NOT NULL DEFAULT 'student'
                                CHECK (role IN ('student','tutor','admin')),
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    last_login_at  TIMESTAMPTZ
);
CREATE INDEX idx_users_role ON users(role);

-- ============================================================================
-- 2. Темы — узлы графа знаний
-- ============================================================================
CREATE TABLE topics (
    topic_id      VARCHAR(40)  PRIMARY KEY,    -- осмысленный slug: 'elasticity', 'gdp'
    name          VARCHAR(160) NOT NULL,
    description   TEXT,
    difficulty    SMALLINT     NOT NULL CHECK (difficulty BETWEEN 1 AND 5),
    section       VARCHAR(60)  NOT NULL        -- 'micro','macro','finance','intro'
                                CHECK (section IN ('intro','micro','macro','finance','game-theory'))
);
CREATE INDEX idx_topics_section ON topics(section);

-- ============================================================================
-- 3. Граф пререквизитов (рёбра)
-- Если (A, B): "тему A нужно знать, чтобы изучать B".
-- ============================================================================
CREATE TABLE topic_prereqs (
    prereq_id   VARCHAR(40) NOT NULL REFERENCES topics(topic_id) ON DELETE CASCADE,
    topic_id    VARCHAR(40) NOT NULL REFERENCES topics(topic_id) ON DELETE CASCADE,
    PRIMARY KEY (prereq_id, topic_id),
    CHECK (prereq_id <> topic_id)
);
CREATE INDEX idx_prereq_topic ON topic_prereqs(topic_id);

-- ============================================================================
-- 4. Источники задач — олимпиадные архивы
-- ============================================================================
CREATE TABLE sources (
    source_id    SERIAL       PRIMARY KEY,
    title        VARCHAR(200) NOT NULL,
    organization VARCHAR(120),
    year         SMALLINT,
    url          VARCHAR(500),
    CHECK (year IS NULL OR (year BETWEEN 1990 AND 2100))
);

-- ============================================================================
-- 5. Задачи
-- ============================================================================
CREATE TABLE tasks (
    task_id       SERIAL       PRIMARY KEY,
    title         VARCHAR(200) NOT NULL,
    body_md       TEXT         NOT NULL,         -- условие задачи (markdown)
    answer        TEXT         NOT NULL,         -- эталонный ответ
    explanation   TEXT,                          -- разбор
    difficulty    SMALLINT     NOT NULL CHECK (difficulty BETWEEN 1 AND 5),
    type          VARCHAR(20)  NOT NULL DEFAULT 'choice'
                               CHECK (type IN ('choice','short','numeric','open')),
    source_id     INTEGER      REFERENCES sources(source_id) ON DELETE SET NULL,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX idx_tasks_difficulty ON tasks(difficulty);
CREATE INDEX idx_tasks_source     ON tasks(source_id);

-- ============================================================================
-- 6. Связка задача-тема (многие-ко-многим)
-- В олимпиадах задача нередко затрагивает несколько тем; основная отмечена is_primary.
-- ============================================================================
CREATE TABLE task_topics (
    task_id    INTEGER     NOT NULL REFERENCES tasks(task_id)   ON DELETE CASCADE,
    topic_id   VARCHAR(40) NOT NULL REFERENCES topics(topic_id) ON DELETE CASCADE,
    is_primary BOOLEAN     NOT NULL DEFAULT false,
    PRIMARY KEY (task_id, topic_id)
);
CREATE INDEX idx_task_topics_topic ON task_topics(topic_id);

-- ============================================================================
-- 7. Mastery — текущая оценка владения темой по пользователю
-- ============================================================================
CREATE TABLE user_mastery (
    user_id     INTEGER     NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    topic_id    VARCHAR(40) NOT NULL REFERENCES topics(topic_id) ON DELETE CASCADE,
    mastery     REAL        NOT NULL DEFAULT 0.0
                            CHECK (mastery BETWEEN 0.0 AND 1.0),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, topic_id)
);

-- ============================================================================
-- 8. Попытки решения — журнал, источник истины для аналитики
-- ============================================================================
CREATE TABLE attempts (
    attempt_id   BIGSERIAL   PRIMARY KEY,
    user_id      INTEGER     NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    task_id      INTEGER     NOT NULL REFERENCES tasks(task_id) ON DELETE CASCADE,
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    is_correct   BOOLEAN     NOT NULL,
    feedback     VARCHAR(20) NOT NULL
                             CHECK (feedback IN ('solved','failed','too_easy','too_hard','skipped')),
    time_spent_s INTEGER     CHECK (time_spent_s IS NULL OR time_spent_s >= 0)
);
CREATE INDEX idx_attempts_user_time ON attempts(user_id, submitted_at DESC);
CREATE INDEX idx_attempts_task      ON attempts(task_id);
CREATE INDEX idx_attempts_feedback  ON attempts(feedback);

-- ============================================================================
-- Полезный view: текущий профиль пользователя
-- ============================================================================
CREATE OR REPLACE VIEW v_user_profile AS
SELECT  u.user_id,
        u.display_name,
        COUNT(DISTINCT a.task_id)                                       AS tasks_attempted,
        COUNT(DISTINCT a.task_id) FILTER (WHERE a.is_correct)           AS tasks_solved,
        ROUND(AVG(um.mastery)::numeric, 3)                              AS avg_mastery,
        COUNT(*) FILTER (WHERE um.mastery >= 0.7)                       AS topics_mastered
FROM    users u
LEFT JOIN attempts     a  ON a.user_id  = u.user_id
LEFT JOIN user_mastery um ON um.user_id = u.user_id
GROUP BY u.user_id, u.display_name;

-- ============================================================================
-- SQLite-совместимость:
-- Если запускать на SQLite, выполнить с заменой:
--   SERIAL       -> INTEGER PRIMARY KEY AUTOINCREMENT
--   BIGSERIAL    -> INTEGER PRIMARY KEY AUTOINCREMENT
--   TIMESTAMPTZ  -> TEXT (хранить в ISO-8601)
--   FILTER (...) -> заменить на CASE WHEN ... THEN 1 END в SUM/COUNT
-- ============================================================================
