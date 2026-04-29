import { escapeHtml } from './utils.js';

const STORAGE_KEY = 'yurikey_script_history';
const MAX_ENTRIES = 240;

export function getHistory() {
  try {
    return JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]');
  } catch { return []; }
}

export function addEntry(scriptName, output) {
  if (typeof output !== 'string') output = String(output || '');
  if (!output.trim()) return;
  const entries = getHistory();
  entries.unshift({ script: scriptName, output, time: new Date().toISOString() });
  if (entries.length > MAX_ENTRIES) entries.length = MAX_ENTRIES;
  try { localStorage.setItem(STORAGE_KEY, JSON.stringify(entries)); } catch { /* storage full */ }
}

export function clearHistory() {
  try { localStorage.removeItem(STORAGE_KEY); } catch { /* ignore */ }
}

export async function openHistoryDialog() {
  const entries = await getHistory();
  const isEmpty = !entries || entries.length === 0;

  const content = isEmpty
    ? '<p class="mdui-typescale-body-medium empty-history" data-i18n="script_history_empty">No script history yet</p>'
    : entries.map(e => `
        <div class="history-entry">
          <p class="mdui-typescale-label-medium history-script">${escapeHtml(e.script)}</p>
          <p class="mdui-typescale-body-small history-time">${e.time}</p>
          <pre class="history-output">${escapeHtml(e.output)}</pre>
          <mdui-divider></mdui-divider>
        </div>
      `).join('');

  const { getTranslation } = await import('./i18n.js');

  mdui.dialog({
    headline: getTranslation('script_history_title') || 'Script History',
    body: `<div class="history-list">${content}</div>`,
    actions: [
      {
        text: getTranslation('dialog_clear') || 'Clear',
        onClick: async () => { await clearHistory(); openHistoryDialog(); return false; }
      },
      { text: getTranslation('dialog_close') || 'Close' }
    ],
    scrollTargetSelectors: '.history-list',
    closeOnOverlayClick: true,
  });
}
