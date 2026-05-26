// Адаптивный движок подбора задач (async, поверх IndexedDB-Storage).
window.Engine = (() => {
  const DEFAULT_MASTERY = 0.0;

  let _mastery = {};

  async function preload() {
    _mastery = await Storage.getMastery();
  }
  function topicById(id)   { return TOPICS.find(t => t.id === id); }
  function upstream(id)    { const t = topicById(id); return t ? t.prereq : []; }
  function downstream(id)  { return TOPICS.filter(t => t.prereq.includes(id)).map(t => t.id); }
  function getMastery(id)  { return _mastery[id] === undefined ? DEFAULT_MASTERY : _mastery[id]; }
  async function setMastery(id, v) {
    _mastery[id] = Math.max(0, Math.min(1, v));
    await Storage.setMastery(_mastery);
  }
  // Разблокировка темы: все прямые пререквизиты должны быть освоены >= 0.2.
  // Достаточно одного успешного "Решил" (даёт +0.15) или одного "Слишком просто" (+0.25).
  const UNLOCK_THRESHOLD = 0.2;
  function isUnlocked(id) {
    const t = topicById(id);
    if (!t) return false;
    return t.prereq.every(p => getMastery(p) >= UNLOCK_THRESHOLD);
  }

  function topicsWithAvailableTasks(excludeTaskIds) {
    // Темы, у которых есть хоть одна задача, которой нет в exclude.
    const ex = new Set(excludeTaskIds || []);
    const cover = new Set();
    TASKS.forEach(t => { if (!ex.has(t.id)) cover.add(t.topic); });
    return cover;
  }

  function pickNextTopic(prefer, excludeTaskIds) {
    const usable = topicsWithAvailableTasks(excludeTaskIds);

    let candidates = TOPICS.filter(t => isUnlocked(t.id) && usable.has(t.id));

    if (prefer && prefer.startsWith('upstream:')) {
      const from = prefer.slice('upstream:'.length);
      const ups  = upstream(from).filter(u => isUnlocked(u) && usable.has(u)).map(topicById);
      if (ups.length) candidates = ups;
    } else if (prefer && prefer.startsWith('downstream:')) {
      const from = prefer.slice('downstream:'.length);
      const dns  = downstream(from).filter(d => isUnlocked(d) && usable.has(d)).map(topicById);
      if (dns.length) candidates = dns;
    }

    if (!candidates.length) {
      // Полный fallback: любая разблокированная с задачами
      candidates = TOPICS.filter(t => isUnlocked(t.id) && usable.has(t.id));
    }
    if (!candidates.length) {
      // Совсем нет — возвращаемся к intro
      return topicById('intro');
    }

    // Сортируем по близости mastery к 0.5
    candidates.sort((a, b) =>
      Math.abs(getMastery(a.id) - 0.5) - Math.abs(getMastery(b.id) - 0.5));
    return candidates[0];
  }

  // Возвращает СОГЛАСОВАННУЮ пару {topic, task} — task всегда из вернувшейся темы.
  function pickTaskAndTopic(topicId, excludeTaskIds = []) {
    const ex = new Set(excludeTaskIds);
    const tryTopic = (tid) => {
      const candidates = TASKS.filter(t => t.topic === tid && !ex.has(t.id));
      if (!candidates.length) return null;
      const m = getMastery(tid);
      const targetDiff = Math.max(1, Math.min(5, Math.round(1 + m * 4)));
      candidates.sort((a, b) =>
        Math.abs(a.difficulty - targetDiff) - Math.abs(b.difficulty - targetDiff));
      return { topic: topicById(tid), task: candidates[0] };
    };
    // 1) Прямо в этой теме
    let r = tryTopic(topicId);
    if (r) return r;
    // 2) Поиск волной по соседям (BFS) — сначала downstream, затем upstream
    const seen = new Set([topicId]);
    const queue = [...downstream(topicId), ...upstream(topicId)];
    while (queue.length) {
      const tid = queue.shift();
      if (seen.has(tid)) continue;
      seen.add(tid);
      r = tryTopic(tid);
      if (r) return r;
      queue.push(...downstream(tid), ...upstream(tid));
    }
    // 3) Полный fallback — любая задача не из exclude
    const others = TASKS.filter(t => !ex.has(t.id));
    if (others.length) {
      const task = others[Math.floor(Math.random() * others.length)];
      return { topic: topicById(task.topic), task };
    }
    return null;
  }

  // Старая обёртка — для совместимости (возвращает только task)
  function pickTask(topicId, excludeTaskIds = []) {
    const r = pickTaskAndTopic(topicId, excludeTaskIds);
    return r ? r.task : TASKS[0];
  }

  async function recordAttempt(taskId, topicId, action, correct) {
    await Storage.appendHistory({ ts: Date.now(), taskId, topicId, action, correct });
    let delta = 0;
    if      (action === 'solved')   delta = +0.15;
    else if (action === 'too_easy') delta = +0.25;
    else if (action === 'failed')   delta = -0.20;
    else if (action === 'too_hard') delta = -0.10;
    await setMastery(topicId, getMastery(topicId) + delta);
    if (action === 'solved' || action === 'too_easy') return 'downstream:' + topicId;
    return 'upstream:' + topicId;
  }

  async function nextRecommendation(prefer, excludeId) {
    const hist = await Storage.getHistory();
    const recent = hist.slice(-5).map(h => h.taskId);
    if (excludeId) recent.push(excludeId);

    const topicGuess = pickNextTopic(prefer, recent);
    const r = pickTaskAndTopic(topicGuess.id, recent);
    return r || { topic: topicGuess, task: TASKS[0] };
  }

  return { preload, pickNextTopic, pickTask, pickTaskAndTopic, recordAttempt,
           nextRecommendation, getMastery, setMastery,
           upstream, downstream, isUnlocked, topicById };
})();
