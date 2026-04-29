import { initBridge, spawnScript, getModuleDir as getBridgeModuleDir } from './bridge.js';
import { setModuleDir, migrateLocalStorage, cfgGet } from './cfg.js';
import { initDevice, refreshDevice } from './device.js';
import { initClock } from './clock.js';
import { initNetwork } from './network.js';
import { initTheme } from './theme.js';
import { initI18n } from './i18n.js';
import { loadContributors } from './contributors.js';
import { initRedirect } from './redirect.js';
import { openHistoryDialog, addEntry } from './history.js';

document.addEventListener('DOMContentLoaded', async () => {
  try {
    await initBridge();
    setModuleDir(getBridgeModuleDir());
    await migrateLocalStorage();
  } catch (e) {
    console.warn('Bridge init failed, running without module path:', e);
  }

  const savedTheme = await cfgGet('theme', 'dark') || 'dark';
  initTheme(savedTheme);
  wireNavigation();
  wireActions();
  wireVersionCard();
  wireRefreshButton();
  await initI18n();
  initClock();
  initNetwork();
  initDevice();
  loadContributors();
  initRedirect();
});

function wireNavigation() {
  const navBar = document.getElementById('nav-bar');
  const pages = {
    home: document.getElementById('home-page'),
    actions: document.getElementById('actions-page'),
    advanced: document.getElementById('advanced-page'),
    settings: document.getElementById('settings-page'),
  };

  navBar.addEventListener('change', () => {
    const active = navBar.value;
    Object.entries(pages).forEach(([key, el]) => {
      el.hidden = key !== active;
    });
    window.scrollTo({ top: 0, behavior: 'instant' });
  });
}

function wireActions() {
  document.querySelectorAll('.action-item[data-script]').forEach(item => {
    item.addEventListener('click', async () => {
      if (item.disabled) return;

      const scriptName = item.dataset.script;
      const spinner = item.querySelector('.action-spinner');
      const { getTranslation } = await import('./i18n.js');

      item.disabled = true;
      spinner?.classList.remove('hidden');

      const lines = [];
      const dialog = mdui.dialog({
        headline: scriptName,
        body: '<div class="terminal"><pre id="live-output"></pre></div>',
        actions: [{ text: getTranslation('dialog_close') || 'Close' }],
        closeOnOverlayClick: false,
      });

      const pre = dialog.querySelector?.('#live-output') || document.getElementById('live-output');

      const child = spawnScript(scriptName, 'feature');
      child.stdout.on('data', line => {
        lines.push(line);
        if (pre) pre.textContent += line + '\n';
        if (pre?.parentElement) pre.parentElement.scrollTop = pre.parentElement.scrollHeight;
      });
      child.stderr.on('data', line => {
        lines.push('[!] ' + line);
        if (pre) pre.textContent += '[!] ' + line + '\n';
        if (pre?.parentElement) pre.parentElement.scrollTop = pre.parentElement.scrollHeight;
      });
      child.on('exit', () => {
        addEntry(scriptName, lines.join('\n'));
        item.disabled = false;
        spinner?.classList.add('hidden');
      });
      child.on('error', err => {
        const msg = err.message || 'Unknown error';
        addEntry(scriptName, msg);
        item.disabled = false;
        spinner?.classList.add('hidden');
      });
    });
  });
}

function wireVersionCard() {
  const card = document.getElementById('version-card');
  if (card) card.addEventListener('click', openHistoryDialog);
}

function wireRefreshButton() {
  const btn = document.getElementById('refresh-btn');
  if (!btn) return;
  btn.addEventListener('click', async () => {
    btn.loading = true;
    await refreshDevice();
    btn.loading = false;
  });
}

