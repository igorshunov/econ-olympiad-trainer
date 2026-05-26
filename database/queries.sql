-- ============================================================================
-- EconTrainer — демонстрационные SQL-запросы (УП.11, задание 3)
-- Запускать после schema.sql и seed.sql.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- ЗАПРОС 1.  SELECT с условием (WHERE) + ORDER BY
--   "Все темы из раздела микроэкономики со сложностью не выше 3,
--    отсортированные от простых к сложным".
-- ----------------------------------------------------------------------------
SELECT topic_id, name, difficulty
FROM   topics
WHERE  section = 'micro' AND difficulty <= 3
ORDER  BY difficulty, name;

-- ----------------------------------------------------------------------------
-- ЗАПРОС 2.  INSERT — добавляем новую задачу и сразу привязываем её к теме.
-- ----------------------------------------------------------------------------
INSERT INTO tasks (title, body_md, answer, explanation, difficulty, type, source_id)
VALUES (
  'Перекрёстная эластичность',
  'Цена кофе выросла на 10%, продажи чая выросли на 4%. Найти перекрёстную эластичность.',
  '0.4',
  'E_xy = %ΔQ_y / %ΔP_x = 4/10 = 0.4 (товары-заменители).',
  4, 'numeric', 2
);

INSERT INTO task_topics (task_id, topic_id, is_primary)
VALUES (
  (SELECT MAX(task_id) FROM tasks),
  'elasticity', true
);

-- ----------------------------------------------------------------------------
-- ЗАПРОС 3.  UPDATE — отметить, что у пользователя выросло mastery по теме
--   после серии успешных попыток. Стандартный путь — UPSERT.
-- ----------------------------------------------------------------------------
INSERT INTO user_mastery (user_id, topic_id, mastery, updated_at)
VALUES (4, 'demand', 0.55, now())
ON CONFLICT (user_id, topic_id) DO UPDATE
SET mastery    = EXCLUDED.mastery,
    updated_at = EXCLUDED.updated_at;

-- альтернативный простой UPDATE для иллюстрации (для тех СУБД, где нет UPSERT):
UPDATE user_mastery
SET    mastery    = LEAST(1.0, mastery + 0.1),
       updated_at = now()
WHERE  user_id    = 3
  AND  topic_id   = 'surplus';

-- ----------------------------------------------------------------------------
-- ЗАПРОС 4.  DELETE — чистим попытки старше N месяцев (политика хранения данных).
-- ----------------------------------------------------------------------------
DELETE FROM attempts
WHERE submitted_at < now() - INTERVAL '12 months';

-- ----------------------------------------------------------------------------
-- ЗАПРОС 5.  SELECT с JOIN — топ задач, которые чаще всего проваливают.
-- Связываем attempts → tasks → task_topics → topics, чтобы понимать, по каким
-- темам "красная зона". Это ключевой запрос для наставника/админа.
-- ----------------------------------------------------------------------------
SELECT  t.task_id,
        t.title,
        t.difficulty,
        tp.topic_id,
        top.name                                       AS topic_name,
        COUNT(*) FILTER (WHERE a.is_correct = false)   AS fails,
        COUNT(*) FILTER (WHERE a.is_correct = true)    AS solves,
        ROUND(
          1.0 * COUNT(*) FILTER (WHERE a.is_correct = false)
              / NULLIF(COUNT(*), 0), 2)                AS fail_rate
FROM    attempts    a
JOIN    tasks       t   ON t.task_id   = a.task_id
JOIN    task_topics tp  ON tp.task_id  = t.task_id AND tp.is_primary = true
JOIN    topics      top ON top.topic_id = tp.topic_id
GROUP BY t.task_id, t.title, t.difficulty, tp.topic_id, top.name
HAVING  COUNT(*) >= 2
ORDER BY fail_rate DESC, fails DESC
LIMIT 20;

-- ----------------------------------------------------------------------------
-- ЗАПРОС 6 (бонус). SELECT с JOIN + подзапрос: для пользователя N подобрать
--   "темы для следующей тренировки" — те, у которых пререквизиты освоены
--   на ≥0.7, а сама тема либо вообще не тронута, либо имеет mastery в зоне
--   ближайшего развития 0.3..0.7.
-- ----------------------------------------------------------------------------
WITH user_id_p AS (SELECT 3 AS uid),
ready_topics AS (
  SELECT t.topic_id, t.name, t.difficulty
  FROM   topics t
  WHERE  NOT EXISTS (
            SELECT 1
            FROM   topic_prereqs tp
            LEFT JOIN user_mastery um
                   ON um.topic_id = tp.prereq_id AND um.user_id = (SELECT uid FROM user_id_p)
            WHERE  tp.topic_id = t.topic_id
              AND  COALESCE(um.mastery, 0) < 0.7
         )
),
self_m AS (
  SELECT topic_id, mastery
  FROM   user_mastery
  WHERE  user_id = (SELECT uid FROM user_id_p)
)
SELECT  r.topic_id,
        r.name,
        r.difficulty,
        COALESCE(s.mastery, 0)                       AS current_mastery,
        CASE
          WHEN s.mastery IS NULL          THEN 'не начато'
          WHEN s.mastery BETWEEN 0.3 AND 0.7 THEN 'в зоне развития'
          ELSE 'другое'
        END                                          AS status
FROM    ready_topics r
LEFT JOIN self_m s ON s.topic_id = r.topic_id
WHERE   s.mastery IS NULL OR s.mastery BETWEEN 0.3 AND 0.7
ORDER BY r.difficulty, current_mastery;

-- ----------------------------------------------------------------------------
-- ЗАПРОС 7 (бонус). Аналитика для наставника — недельный отчёт активности.
-- ----------------------------------------------------------------------------
SELECT  u.display_name,
        DATE_TRUNC('day', a.submitted_at)::date  AS day,
        COUNT(*)                                  AS attempts,
        COUNT(*) FILTER (WHERE a.is_correct)      AS solved,
        COUNT(DISTINCT t.task_id)                 AS unique_tasks
FROM    users u
JOIN    attempts a ON a.user_id = u.user_id
JOIN    tasks    t ON t.task_id = a.task_id
WHERE   u.role = 'student'
  AND   a.submitted_at >= now() - INTERVAL '14 days'
GROUP BY u.display_name, day
ORDER BY day DESC, u.display_name;
