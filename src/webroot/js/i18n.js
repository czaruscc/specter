import { cfgGet, cfgSet } from './cfg.js';

let currentStrings = {};
let fallbackStrings = {};

export async function initI18n() {
  // Pre-load English as fallback for missing translations
  try {
    const res = await fetch(`lang/source/string.json?ts=${Date.now()}`);
    fallbackStrings = await res.json();
  } catch { fallbackStrings = {}; }

  const saved = await cfgGet('lang', 'en') || 'en';
  await applyLanguage(saved, true);
  wireLanguageSelect(saved);
}

export async function applyLanguage(langCode) {
  const url = langCode === 'en'
    ? `lang/source/string.json?ts=${Date.now()}`
    : `lang/${langCode}.json?ts=${Date.now()}`;

  try {
    const res = await fetch(url);
    currentStrings = await res.json();
  } catch {
    currentStrings = {};
  }

  applyTranslations();
  cfgSet('lang', langCode);
  document.dispatchEvent(new CustomEvent('languageChanged', { detail: { langCode } }));
}

export function getTranslation(key) {
  return currentStrings[key] || fallbackStrings[key] || null;
}

export function getStrings() {
  return currentStrings;
}

function applyTranslations() {
  document.querySelectorAll('[data-i18n]').forEach(el => {
    const key = el.dataset.i18n;

    if (el.tagName === 'TITLE') {
      const val = currentStrings[key] || fallbackStrings[key];
      if (val) document.title = val;
      return;
    }

    // Try current language first, fall back to English
    const val = currentStrings[key] || fallbackStrings[key];
    if (!val) return;

    if (val.includes('<')) {
      el.innerHTML = val;
    } else {
      while (el.firstChild) el.removeChild(el.firstChild);
      el.appendChild(document.createTextNode(val));
    }
  });

}

function wireLanguageSelect(currentLang) {
  const select = document.getElementById('language-select');
  if (!select) return;

  // Wait for mdui-select to be upgraded before populating
  customElements.whenDefined('mdui-select').then(() => {

  const LANGUAGES = [
    ['en', '🇬🇧', 'English'],
    ['zh', '🇨🇳', '中文'],
    ['ru', '🇷🇺', 'Русский'],
    ['es', '🇪🇸', 'Español'],
    ['pt', '🇵🇹', 'Português'],
    ['hi', '🇮🇳', 'हिन्दी'],
    ['ar', '🇸🇦', 'العربية'],
    ['fr', '🇫🇷', 'Français'],
    ['de', '🇩🇪', 'Deutsch'],
    ['tr', '🇹🇷', 'Türkçe'],
  ];

  LANGUAGES.forEach(([code, flag, name]) => {
    const item = document.createElement('mdui-menu-item');
    item.value = code;
    item.textContent = `${flag} ${name}`;
    item.addEventListener('click', async () => {
      try {
        await applyLanguage(code);
        select.value = code;
      } catch (e) {
        console.warn('Language change failed:', e);
      }
    });
    select.appendChild(item);
  });

  select.value = currentLang;
  });
}
