// Адаптивный движок подбора задач.
// Идея: для каждой темы храним mastery в [0..1].
// Следующая тема — та, где mastery близко к 0.5 (зона ближайшего развития).
// Если "слишком сложно" / "не решил" — спускаемся к пререквизитам (upstream).
// Если "слишком просто" — поднимаемся к темам, для которых эта тема — пререквизит (downstream).
window.Engine = (() => {
  const DEFAULT_MASTERY = 0.0;

  // --- Helpers over graph ---
  function topicById(id) { return TOPICS.find(t => t.id === id); }
  function upstream(id) {
    const t = topicById(id);
    return t ? t.prereq : [];
  }
  function downstream(id) {
    return TOPICS.filter(t => t.prereq.includes(id)).map(t => t.id);
  }
  function getMastery(id) {
    const m = Storage.getMastery();
    return m[id] === undefined ? DEFAULT_MASTERY : m[id];
  }
  function setMastery(id, v) {
    const m = Storage.getMastery();
    m[id] = Math.max(0, Math.min(1, v));
    Storage.setMastery(m);
  }
  function isUnlocked(id) {
    // Тема разблокирована, если у всех пререквизитов mastery ≥ 0.3
    const t = topicById(id);
    if (!t) return false;
    return t.prereq.every(p => getMastery(p) >= 0.3);
  }

  // --- Selection ---
  function pickNextTopic(prefer) {
    // prefer: "any" | "upstream:<id>" | "downstream:<id>"
    let candidates = TOPICS.filter(t => isUnlocked(t.id));
    if (prefer && prefer.startsWith("upstream:")) {
      const from = prefer.slice("upstream:".length);
      const ups = upstream(from).filter(u => isUnlocked(u));
      if (ups.length) candidates = ups.map(topicById);
    } else if (prefer && prefer.startsWith("downstream:")) {
      const from = prefer.slice("downstream:".length);
      const dns = downstream(from).filter(d => isUnlocked(d));
      if (dns.length) candidates = dns.map(topicById);
    }
    // Score: предпочитаем темы с mastery ближе к 0.5
    candidates.sort((a, b) => {
      const da = Math.abs(getMastery(a.id) - 0.5);
      const db = Math.abs(getMastery(b.id) - 0.5);
      return da - db;
    });
    return candidates[0] || topicById("intro");
  }

  function pickTask(topicId, excludeTaskIds = []) {
    const tasksOfTopic = TASKS.filter(t => t.topic === topicId && !excludeTaskIds.includes(t.id));
    if (!tasksOfTopic.length) {
      // нет задач из темы — возьмём из любой разблокированной близкой
      const others = TASKS.filter(t => !excludeTaskIds.includes(t.id));
      return others[Math.floor(Math.random() * others.length)] || TASKS[0];
    }
    // Выбираем сложность по mastery: чем выше mastery, тем выше difficulty
    const m = getMastery(topicId);
    const targetDiff = Math.max(1, Math.min(5, Math.round(1 + m * 4)));
    tasksOfTopic.sort((a, b) =>
      Math.abs(a.difficulty - targetDiff) - Math.abs(b.difficulty - targetDiff));
    return tasksOfTopic[0];
  }

  function recordAttempt(taskId, topicId, action, correct) {
    Storage.appendHistory({
      ts: Date.now(),
      taskId, topicId, action, correct
    });
    // Обновляем mastery
    let delta = 0;
    if (action === "solved")        delta = +0.15;
    else if (action === "too_easy") delta = +0.25;
    else if (action === "failed")   delta = -0.20;
    else if (action === "too_hard") delta = -0.10;
    setMastery(topicId, getMastery(topicId) + delta);

    // Какую следующую тему искать?
    if (action === "solved" || action === "too_easy") return "downstream:" + topicId;
    return "upstream:" + topicId;
  }

  function nextRecommendation(prefer) {
    const topic = pickNextTopic(prefer);
    const recent = Storage.getHistory().slice(-5).map(h => h.taskId);
    const task = pickTask(topic.id, recent);
    return { topic, task };
  }

  return { pickNextTopic, pickTask, recordAttempt,
           nextRecommendation, getMastery, setMastery,
           upstream, downstream, isUnlocked, topicById };
})();
