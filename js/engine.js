// Адаптивный движок подбора задач (async, поверх IndexedDB-Storage).
window.Engine = (() => {
  const DEFAULT_MASTERY = 0.0;

  let _mastery = {}; // memoized cache; persists via Storage

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
  function isUnlocked(id) {
    const t = topicById(id);
    if (!t) return false;
    return t.prereq.every(p => getMastery(p) >= 0.3);
  }

  function pickNextTopic(prefer) {
    let candidates = TOPICS.filter(t => isUnlocked(t.id));
    if (prefer && prefer.startsWith('upstream:')) {
      const from = prefer.slice('upstream:'.length);
      const ups = upstream(from).filter(u => isUnlocked(u));
      if (ups.length) candidates = ups.map(topicById);
    } else if (prefer && prefer.startsWith('downstream:')) {
      const from = prefer.slice('downstream:'.length);
      const dns = downstream(from).filter(d => isUnlocked(d));
      if (dns.length) candidates = dns.map(topicById);
    }
    candidates.sort((a, b) =>
      Math.abs(getMastery(a.id) - 0.5) - Math.abs(getMastery(b.id) - 0.5));
    return candidates[0] || topicById('intro');
  }

  function pickTask(topicId, excludeTaskIds = []) {
    const here = TASKS.filter(t => t.topic === topicId && !excludeTaskIds.includes(t.id));
    if (!here.length) {
      const others = TASKS.filter(t => !excludeTaskIds.includes(t.id));
      return others[Math.floor(Math.random() * others.length)] || TASKS[0];
    }
    const m = getMastery(topicId);
    const targetDiff = Math.max(1, Math.min(5, Math.round(1 + m * 4)));
    here.sort((a, b) =>
      Math.abs(a.difficulty - targetDiff) - Math.abs(b.difficulty - targetDiff));
    return here[0];
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

  async function nextRecommendation(prefer) {
    const topic = pickNextTopic(prefer);
    const hist = await Storage.getHistory();
    const recent = hist.slice(-5).map(h => h.taskId);
    const task = pickTask(topic.id, recent);
    return { topic, task };
  }

  return { preload, pickNextTopic, pickTask, recordAttempt,
           nextRecommendation, getMastery, setMastery,
           upstream, downstream, isUnlocked, topicById };
})();
