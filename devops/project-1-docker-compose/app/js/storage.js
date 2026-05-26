// Persistent storage. Использует IndexedDB через тонкую обёртку
// (idb-keyval подгружается из CDN в html). Fallback на localStorage,
// если IndexedDB недоступен (приватный режим в некоторых браузерах).
window.Storage = (() => {
  const NS = 'econtrainer';
  const KEY_USER = 'user';
  const KEY_MASTERY = 'mastery';
  const KEY_HISTORY = 'history';

  // idbKeyval должен быть глобально доступен (см. <script src="...idb-keyval...">)
  const useIdb = typeof idbKeyval !== 'undefined';
  let store = null;
  if (useIdb) {
    store = idbKeyval.createStore(NS, 'kv');
  }

  async function get(key, fallback) {
    try {
      if (useIdb) {
        const v = await idbKeyval.get(key, store);
        return v === undefined ? fallback : v;
      }
    } catch (e) { console.warn('IndexedDB get failed:', e); }
    const raw = localStorage.getItem(NS + ':' + key);
    return raw ? JSON.parse(raw) : fallback;
  }
  async function set(key, value) {
    try {
      if (useIdb) { await idbKeyval.set(key, value, store); return; }
    } catch (e) { console.warn('IndexedDB set failed:', e); }
    localStorage.setItem(NS + ':' + key, JSON.stringify(value));
  }
  async function del(key) {
    try {
      if (useIdb) { await idbKeyval.del(key, store); return; }
    } catch (e) { /* */ }
    localStorage.removeItem(NS + ':' + key);
  }

  return {
    async getUser()      { return await get(KEY_USER, null); },
    async setUser(u)     { await set(KEY_USER, u); },
    async clearUser()    { await del(KEY_USER); },

    async getMastery()   { return await get(KEY_MASTERY, {}); },
    async setMastery(m)  { await set(KEY_MASTERY, m); },

    async getHistory()   { return await get(KEY_HISTORY, []); },
    async appendHistory(rec) {
      const h = await get(KEY_HISTORY, []);
      h.push(rec);
      await set(KEY_HISTORY, h);
    },

    async resetProgress() {
      await del(KEY_MASTERY);
      await del(KEY_HISTORY);
    },

    backend: useIdb ? 'IndexedDB' : 'localStorage',
  };
})();
