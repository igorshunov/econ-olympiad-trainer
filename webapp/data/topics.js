// Граф тем для тренажёра. Узлы = темы, рёбра = "является пререквизитом".
// Если A -> B, значит A нужно знать, чтобы изучать B.
window.TOPICS = [
  // === Базовые понятия ===
  { id: "intro",            name: "Базовые понятия экономики",        difficulty: 1, prereq: [] },
  { id: "needs_resources",  name: "Потребности и ограниченность ресурсов", difficulty: 1, prereq: ["intro"] },
  { id: "ppc",              name: "Кривая производственных возможностей", difficulty: 2, prereq: ["needs_resources"] },
  { id: "opp_cost",         name: "Альтернативные издержки",          difficulty: 2, prereq: ["ppc"] },
  { id: "comp_advantage",   name: "Сравнительное преимущество, обмен", difficulty: 3, prereq: ["opp_cost"] },

  // === Микроэкономика: спрос-предложение ===
  { id: "demand",           name: "Спрос: закон, неценовые факторы",  difficulty: 1, prereq: ["intro"] },
  { id: "supply",           name: "Предложение: закон, неценовые факторы", difficulty: 1, prereq: ["intro"] },
  { id: "equilibrium",      name: "Рыночное равновесие",              difficulty: 2, prereq: ["demand","supply"] },
  { id: "elasticity",       name: "Эластичность спроса и предложения", difficulty: 3, prereq: ["equilibrium"] },
  { id: "surplus",          name: "Излишки потребителя и производителя", difficulty: 3, prereq: ["equilibrium"] },
  { id: "taxes_subsidies",  name: "Налоги, субсидии, потолки/полы цен", difficulty: 4, prereq: ["elasticity","surplus"] },

  // === Микроэкономика: фирма ===
  { id: "production",       name: "Производственная функция",         difficulty: 3, prereq: ["needs_resources"] },
  { id: "costs",            name: "Издержки фирмы (FC, VC, MC, AC)",  difficulty: 3, prereq: ["production"] },
  { id: "profit_max",       name: "Максимизация прибыли (MR=MC)",     difficulty: 4, prereq: ["costs"] },
  { id: "perfect_comp",     name: "Совершенная конкуренция",          difficulty: 4, prereq: ["profit_max","surplus"] },
  { id: "monopoly",         name: "Монополия и ценовая дискриминация", difficulty: 5, prereq: ["profit_max","elasticity"] },
  { id: "oligopoly",        name: "Олигополия (Курно, Бертран)",      difficulty: 5, prereq: ["monopoly"] },
  { id: "game_theory",      name: "Теория игр: доминирование, Нэш",   difficulty: 5, prereq: ["oligopoly"] },

  // === Поведенческая ===
  { id: "utility",          name: "Полезность, бюджетное ограничение", difficulty: 3, prereq: ["demand"] },
  { id: "indifference",     name: "Кривые безразличия, оптимум",      difficulty: 4, prereq: ["utility"] },

  // === Макроэкономика ===
  { id: "gdp",              name: "ВВП: расчёт, номинал/реал",        difficulty: 3, prereq: ["intro"] },
  { id: "inflation",        name: "Инфляция, индексы цен",            difficulty: 3, prereq: ["gdp"] },
  { id: "unemployment",     name: "Безработица: виды, оценка",        difficulty: 3, prereq: ["gdp"] },
  { id: "ad_as",            name: "Модель AD-AS",                     difficulty: 4, prereq: ["inflation","unemployment"] },
  { id: "monetary_pol",     name: "Денежно-кредитная политика",       difficulty: 5, prereq: ["ad_as"] },
  { id: "fiscal_pol",       name: "Бюджетно-налоговая политика",      difficulty: 5, prereq: ["ad_as"] },

  // === Финансовая ===
  { id: "interest",         name: "Простой и сложный процент",        difficulty: 2, prereq: ["intro"] },
  { id: "annuity",          name: "Аннуитеты, кредиты",               difficulty: 3, prereq: ["interest"] },
  { id: "npv",              name: "NPV, IRR, дисконтирование",        difficulty: 4, prereq: ["annuity"] },
];
