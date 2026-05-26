-- =============================================================================
-- EconTrainer — наполнение базы данных тестовыми данными.
-- Запускать после schema.sql.
-- =============================================================================

-- 1. Пользователи (пароли в реальности — bcrypt-хэши, тут заглушки $2b$...)
INSERT INTO users (email, password_hash, display_name, role) VALUES
  ('admin@econtrainer.ru', '$2b$12$adminhashplaceholder...........', 'Администратор', 'admin'),
  ('teacher@hsemath.ru',   '$2b$12$tutorhashplaceholder...........', 'Анна Петрова (наставник)', 'tutor'),
  ('ivan@example.com',     '$2b$12$studenthash1placeholder.........', 'Иван Иванов', 'student'),
  ('maria@example.com',    '$2b$12$studenthash2placeholder.........', 'Мария Кузнецова', 'student'),
  ('petr@example.com',     '$2b$12$studenthash3placeholder.........', 'Петр Сидоров', 'student');

-- 2. Источники
INSERT INTO sources (title, organization, year, url) VALUES
  ('ВсОШ по экономике, региональный этап',     'Минпросвещения РФ',     2024, 'https://olimpiada.ru/'),
  ('ВсОШ по экономике, заключительный этап',   'Минпросвещения РФ',     2024, 'https://olimpiada.ru/'),
  ('Высшая Проба, экономика',                  'НИУ ВШЭ',               2024, 'https://olymp.hse.ru/'),
  ('Олимпиада МГУ "Ломоносов", экономика',     'МГУ им. М.В. Ломоносова',2024,'https://olymp.msu.ru/'),
  ('Учебный материал кафедры',                 'Колледж Хекслет',       2026, NULL);

-- 3. Темы
INSERT INTO topics (topic_id, name, difficulty, section, description) VALUES
  ('intro',           'Базовые понятия экономики',                  1, 'intro',   'Объект и предмет экономической науки, базовые проблемы'),
  ('needs_resources', 'Потребности и ограниченность ресурсов',      1, 'intro',   'Факторы производства, классификация потребностей'),
  ('ppc',             'Кривая производственных возможностей',       2, 'intro',   'КПВ, эффективные и неэффективные точки'),
  ('opp_cost',        'Альтернативные издержки',                    2, 'intro',   'Цена выбора, упущенная выгода'),
  ('comp_advantage',  'Сравнительное преимущество, обмен',          3, 'intro',   'Теория Рикардо, специализация и торговля'),
  ('demand',          'Спрос: закон, неценовые факторы',            1, 'micro',   'Закон спроса, факторы сдвига'),
  ('supply',          'Предложение: закон, неценовые факторы',      1, 'micro',   'Закон предложения, факторы сдвига'),
  ('equilibrium',     'Рыночное равновесие',                        2, 'micro',   'Точка равновесия, дефицит и избыток'),
  ('elasticity',      'Эластичность спроса и предложения',          3, 'micro',   'Эластичность по цене, доходу, перекрёстная'),
  ('surplus',         'Излишки потребителя и производителя',        3, 'micro',   'CS, PS, общественное благосостояние'),
  ('taxes_subsidies', 'Налоги, субсидии, потолки и полы цен',       4, 'micro',   'Распределение налогового бремени, DWL'),
  ('production',      'Производственная функция',                   3, 'micro',   'TP, AP, MP; закон убывающей отдачи'),
  ('costs',           'Издержки фирмы (FC, VC, MC, AC)',            3, 'micro',   'Структура издержек, кривые'),
  ('profit_max',      'Максимизация прибыли (MR = MC)',             4, 'micro',   'Условие первого порядка для прибыли'),
  ('perfect_comp',    'Совершенная конкуренция',                    4, 'micro',   'P = MC = minAC в долгосрочном равновесии'),
  ('monopoly',        'Монополия и ценовая дискриминация',          5, 'micro',   'Дедвейт-лосс, виды дискриминации'),
  ('oligopoly',       'Олигополия (Курно, Бертран)',                5, 'micro',   'Модели стратегического взаимодействия'),
  ('game_theory',     'Теория игр: доминирование, Нэш',             5, 'game-theory','Стратегические взаимодействия'),
  ('utility',         'Полезность, бюджетное ограничение',          3, 'micro',   'Кардиналистский подход'),
  ('indifference',    'Кривые безразличия, оптимум',                4, 'micro',   'Ординалистский подход'),
  ('gdp',             'ВВП: расчёт, номинал/реал',                  3, 'macro',   'Методы расчёта, дефлятор, индексы'),
  ('inflation',       'Инфляция, индексы цен',                      3, 'macro',   'CPI, PPI, дефлятор ВВП'),
  ('unemployment',    'Безработица: виды, оценка',                  3, 'macro',   'Фрикционная, структурная, циклическая'),
  ('ad_as',           'Модель AD-AS',                               4, 'macro',   'Совокупный спрос и предложение'),
  ('monetary_pol',    'Денежно-кредитная политика',                 5, 'macro',   'Инструменты ЦБ, передача импульсов'),
  ('fiscal_pol',      'Бюджетно-налоговая политика',                5, 'macro',   'Стимулирующая и сдерживающая ФП'),
  ('interest',        'Простой и сложный процент',                  2, 'finance', 'Формулы и интуиция'),
  ('annuity',         'Аннуитеты, кредиты',                         3, 'finance', 'Регулярные платежи, схемы погашения'),
  ('npv',             'NPV, IRR, дисконтирование',                  4, 'finance', 'Инвестиционная оценка');

-- 4. Граф пререквизитов (рёбра)
INSERT INTO topic_prereqs (prereq_id, topic_id) VALUES
  ('intro',           'needs_resources'),
  ('needs_resources', 'ppc'),
  ('ppc',             'opp_cost'),
  ('opp_cost',        'comp_advantage'),
  ('intro',           'demand'),
  ('intro',           'supply'),
  ('demand',          'equilibrium'),
  ('supply',          'equilibrium'),
  ('equilibrium',     'elasticity'),
  ('equilibrium',     'surplus'),
  ('elasticity',      'taxes_subsidies'),
  ('surplus',         'taxes_subsidies'),
  ('needs_resources', 'production'),
  ('production',      'costs'),
  ('costs',           'profit_max'),
  ('profit_max',      'perfect_comp'),
  ('surplus',         'perfect_comp'),
  ('profit_max',      'monopoly'),
  ('elasticity',      'monopoly'),
  ('monopoly',        'oligopoly'),
  ('oligopoly',       'game_theory'),
  ('demand',          'utility'),
  ('utility',         'indifference'),
  ('intro',           'gdp'),
  ('gdp',             'inflation'),
  ('gdp',             'unemployment'),
  ('inflation',       'ad_as'),
  ('unemployment',    'ad_as'),
  ('ad_as',           'monetary_pol'),
  ('ad_as',           'fiscal_pol'),
  ('intro',           'interest'),
  ('interest',        'annuity'),
  ('annuity',         'npv');

-- 5. Несколько задач (минимально для демо запросов)
INSERT INTO tasks (title, body_md, answer, explanation, difficulty, type, source_id) VALUES
  ('Сдвиг кривой спроса', 'Что приведёт к сдвигу кривой спроса на кофе ВПРАВО?', 'Рост доходов потребителей (нормальный товар)', 'Сдвиг даёт неценовой фактор: для нормального товара рост дохода → сдвиг вправо.', 1, 'choice', 1),
  ('Расчёт равновесия',   'Спрос: Qd = 100 - 2P. Предложение: Qs = 20 + 2P. Найти P* и Q*.', 'P*=20, Q*=60', '100-2P=20+2P → P*=20, Q*=60.', 2, 'numeric', 1),
  ('Эластичность',        'При повышении цены на 5% спрос упал на 10%. Эластичность по модулю?', '2', 'E = 10/5 = 2 → эластичный спрос.', 3, 'numeric', 2),
  ('Излишек потребителя', 'P*=50, Q*=40, максимальная цена 90. Найти CS.', '800', 'CS = 0.5 × (90-50) × 40 = 800.', 3, 'numeric', 2),
  ('Налог и DWL',         'Что произойдёт с суммарным излишком при введении акциза?', 'Уменьшится за счёт DWL', 'Налог сокращает излишки потребителя и производителя сильнее, чем налоговые поступления.', 4, 'choice', 3),
  ('Монополия Курно',     'Дуополия Курно: P = 120 - Q, MC=30. Равновесный q каждой фирмы?', '30', 'q* = (a-c)/(3b) = 90/3 = 30.', 5, 'numeric', 4),
  ('ВВП по доходам',      'Что НЕ включается в ВВП по доходам?', 'Трансферты', 'Трансферты не плата за фактор производства.', 3, 'choice', 1),
  ('Сложный процент',     'Вклад 10000 ₽ под 10% годовых на 2 года (сложный процент). Итог?', '12100', '10000 × 1.1² = 12100.', 2, 'numeric', 5),
  ('NPV проекта',         'Проект: -100, +60, +60. Ставка 10%. Найти NPV.', '4.1', 'NPV = -100 + 60/1.1 + 60/1.21 ≈ 4.1.', 4, 'numeric', 3),
  ('Дилемма заключённого', 'Каково равновесие Нэша в дилемме заключённого?', 'Оба сознаются', 'Доминирующая стратегия для каждого — сознаться.', 5, 'choice', 4);

-- 6. Привязка задач к темам (основная + дополнительные)
INSERT INTO task_topics (task_id, topic_id, is_primary) VALUES
  (1, 'demand',          true),
  (2, 'equilibrium',     true),
  (3, 'elasticity',      true),
  (3, 'demand',          false),
  (4, 'surplus',         true),
  (4, 'equilibrium',     false),
  (5, 'taxes_subsidies', true),
  (5, 'surplus',         false),
  (6, 'oligopoly',       true),
  (6, 'profit_max',      false),
  (7, 'gdp',             true),
  (8, 'interest',        true),
  (9, 'npv',             true),
  (9, 'annuity',         false),
  (10,'game_theory',     true);

-- 7. Mastery — стартовый профиль для трёх студентов
-- Иван (user_id=3) — продвинутый по микро
INSERT INTO user_mastery (user_id, topic_id, mastery) VALUES
  (3, 'intro',       1.00),
  (3, 'demand',      0.90),
  (3, 'supply',      0.85),
  (3, 'equilibrium', 0.75),
  (3, 'elasticity',  0.55),
  (3, 'surplus',     0.40),
  (3, 'gdp',         0.20);

-- Мария (user_id=4) — новичок
INSERT INTO user_mastery (user_id, topic_id, mastery) VALUES
  (4, 'intro',       0.50),
  (4, 'demand',      0.30),
  (4, 'supply',      0.30);

-- Петр (user_id=5) — финансист
INSERT INTO user_mastery (user_id, topic_id, mastery) VALUES
  (5, 'intro',       1.00),
  (5, 'interest',    0.95),
  (5, 'annuity',     0.80),
  (5, 'npv',         0.60),
  (5, 'demand',      0.20);

-- 8. Попытки — журнал, на котором будут демонстрироваться запросы
INSERT INTO attempts (user_id, task_id, is_correct, feedback, time_spent_s, submitted_at) VALUES
  (3, 1, true,  'solved',    25,  '2026-05-20 10:15:00'),
  (3, 2, true,  'solved',   180,  '2026-05-20 10:18:00'),
  (3, 3, true,  'too_easy',  40,  '2026-05-20 10:21:00'),
  (3, 4, false, 'failed',   220,  '2026-05-21 18:05:00'),
  (3, 4, true,  'solved',   190,  '2026-05-22 11:00:00'),
  (3, 5, false, 'too_hard', 350,  '2026-05-23 14:10:00'),
  (3, 7, true,  'solved',    60,  '2026-05-24 09:30:00'),
  (4, 1, false, 'too_hard', 400,  '2026-05-21 12:00:00'),
  (4, 1, true,  'solved',   240,  '2026-05-22 12:00:00'),
  (4, 2, false, 'failed',   600,  '2026-05-22 12:10:00'),
  (5, 8, true,  'solved',    30,  '2026-05-18 19:00:00'),
  (5, 9, false, 'failed',   500,  '2026-05-19 19:00:00'),
  (5, 9, true,  'solved',   400,  '2026-05-20 19:00:00'),
  (5, 1, false, 'too_hard', 250,  '2026-05-21 19:00:00'),
  (5, 1, true,  'solved',   180,  '2026-05-22 19:00:00');
