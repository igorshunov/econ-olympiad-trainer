// Общие UI-функции (async, под IndexedDB storage)
window.UI = (() => {
  async function requireAuth() {
    const u = await Storage.getUser();
    if (!u) { window.location.href = 'index.html'; return null; }
    return u;
  }
  async function renderHeader(activePage, user) {
    user = user || await Storage.getUser();
    const el = document.getElementById('header');
    if (!el) return;
    el.innerHTML = `
      <a href="dashboard.html" class="logo">⚖ EconTrainer</a>
      <nav>
        <a href="dashboard.html" ${activePage==='dashboard'?'class="active"':''}>Граф знаний</a>
        <a href="task.html" ${activePage==='task'?'class="active"':''}>Тренировка</a>
        <a href="progress.html" ${activePage==='progress'?'class="active"':''}>Прогресс</a>
      </nav>
      ${user ? `<div class="user-chip">
        <span>${user.name}</span>
        <a href="#" id="logout-link" style="color:var(--text-dim);text-decoration:none">выйти</a>
      </div>` : ''}
    `;
    const logout = document.getElementById('logout-link');
    if (logout) logout.onclick = async (e) => {
      e.preventDefault();
      await Storage.clearUser();
      window.location.href = 'index.html';
    };
  }
  function masteryColor(m) {
    if (m < 0.2) return 'var(--mastery-0)';
    if (m < 0.4) return 'var(--mastery-1)';
    if (m < 0.6) return 'var(--mastery-2)';
    if (m < 0.8) return 'var(--mastery-3)';
    return 'var(--mastery-4)';
  }
  function toast(msg, ms = 2000) {
    const t = document.createElement('div');
    t.className = 'toast';
    t.textContent = msg;
    document.body.appendChild(t);
    setTimeout(() => t.remove(), ms);
  }
  return { requireAuth, renderHeader, masteryColor, toast };
})();
