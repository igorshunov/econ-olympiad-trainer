// Тонкая прослойка над localStorage — храним пользователя и mastery.
window.Storage = (() => {
  const KEY_USER = "ot_user";
  const KEY_MASTERY = "ot_mastery";
  const KEY_HISTORY = "ot_history";

  function getUser() {
    const raw = localStorage.getItem(KEY_USER);
    return raw ? JSON.parse(raw) : null;
  }
  function setUser(u) { localStorage.setItem(KEY_USER, JSON.stringify(u)); }
  function clearUser() { localStorage.removeItem(KEY_USER); }

  function getMastery() {
    const raw = localStorage.getItem(KEY_MASTERY);
    return raw ? JSON.parse(raw) : {};
  }
  function setMastery(m) { localStorage.setItem(KEY_MASTERY, JSON.stringify(m)); }

  function getHistory() {
    const raw = localStorage.getItem(KEY_HISTORY);
    return raw ? JSON.parse(raw) : [];
  }
  function appendHistory(record) {
    const h = getHistory();
    h.push(record);
    localStorage.setItem(KEY_HISTORY, JSON.stringify(h));
  }

  function resetProgress() {
    localStorage.removeItem(KEY_MASTERY);
    localStorage.removeItem(KEY_HISTORY);
  }

  return { getUser, setUser, clearUser,
           getMastery, setMastery,
           getHistory, appendHistory,
           resetProgress };
})();
