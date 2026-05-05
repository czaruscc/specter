import { shellEscape } from './utils.js';
import { runScript, exec } from './bridge.js';
import { appendToOutput } from './terminal.js';

const INFO_URL = '/json/info.json';
const KEYBOX_INFO_URL = '/json/keybox_info.json';

interface InfoJson {
  android?: string;
  kernel?: string;
  root?: string;
  root_sol?: string;
  version?: string;
  keybox_format?: string;
  flags?: { twrp?: boolean; blacklist?: boolean };
}

interface KeyboxInfoJson {
  installed: boolean;
  source?: string;
  source_version?: string;
  text?: string;
  up_to_date?: boolean;
  revoked?: boolean;
}

export async function initDevice() {
  await refreshDevice();
  await refreshKeyboxStatus();
}

export async function refreshDevice() {
  try {
    const result = await runScript('device-info.sh', 'common');
    if (result.output) {
      result.output.split('\n').filter(Boolean).forEach(l => appendToOutput(`[device-info] ${l}`));
    }
  } catch (e) {
    console.warn('Device info script failed:', e);
  }
  const data = await fetchJson<InfoJson>(INFO_URL);
  if (data) applyAllDeviceInfo(data);
}

export async function refreshKeyboxStatus() {
  try {
    const result = await runScript('keybox_info.sh', 'feature');
    if (result.output) {
      result.output.split('\n').filter(Boolean).forEach(l => appendToOutput(`[keybox] ${l}`));
    }
  } catch (e) {
    console.warn('Keybox info script failed:', e);
  }
  const data = await fetchJson<KeyboxInfoJson>(KEYBOX_INFO_URL);
  if (data) applyKeyboxStatus(data);
}

async function fetchJson<T>(url: string): Promise<T | null> {
  try {
    const res = await fetch(url);
    if (!res.ok) return null;
    return await res.json();
  } catch (e) {
    console.warn('Fetch failed:', url, e);
    return null;
  }
}

function applyAllDeviceInfo(data: InfoJson) {
  applyDeviceInfo(data);
  if (data.flags) applyFlags(data.flags);
  if (data.keybox_format) applyKeyboxFormat(data.keybox_format);
  applyBootStages(data);
}

function applyDeviceInfo(data: InfoJson) {
  setText('android-value', data.android || '—');
  setText('kernel-value', data.kernel || '—');
  setText('root-value', data.root || '—');
  setText('version-info-value', data.version || '—');
  const rootSolEl = document.getElementById('root-sol-value');
  if (rootSolEl && data.root_sol) {
    rootSolEl.textContent = data.root_sol;
  }
}

function applyFlags(flags: { twrp?: boolean; blacklist?: boolean }) {
  if (!flags) return;
  const recoverySwitch = document.getElementById('recovery-switch') as any;
  if (recoverySwitch) recoverySwitch.selected = !!flags.twrp;
  const blacklistSwitch = document.getElementById('blacklist-switch') as any;
  if (blacklistSwitch) blacklistSwitch.selected = !!flags.blacklist;
}

function applyKeyboxFormat(format: string) {
  const el = document.getElementById('keybox-format');
  if (!el) return;
  if (format === 'locked.xml') {
    el.textContent = 'TEE Sim';
    el.className = 'keybox-chip keybox-chip--teesim';
    el.style.display = '';
  } else {
    el.style.display = 'none';
  }
}

function applyBootStages(data: InfoJson) {
  const bar = document.getElementById('boot-stage-bar');
  if (!bar) return;
  if (data.root_sol === "kernelsu" || data.root_sol === "apatch") {
    bar.style.display = 'flex';
    document.querySelectorAll('.boot-stage-dot').forEach(el => {
      const dot = el as HTMLElement;
      if (dot.dataset.stage === 'boot-completed') {
        dot.style.color = 'var(--md-sys-color-tertiary)';
      } else if (dot.dataset.stage === 'post-fs-data' || dot.dataset.stage === 'service') {
        dot.style.color = 'var(--md-sys-color-tertiary)';
      }
    });
  }
}

function applyKeyboxStatus(data: KeyboxInfoJson) {
  const source = document.getElementById('keybox-source')!;
  const statusEl = document.getElementById('keybox-status')!;
  const icon = document.getElementById('keybox-icon')!;
  if (!source || !statusEl || !icon) return;

  if (!data.installed) {
    source.textContent = 'Not Installed';
    source.className = 'keybox-chip keybox-chip--neutral';
    statusEl.style.display = 'none';
    icon.textContent = 'vpn_key_off';
    return;
  }

  statusEl.style.display = '';

  if (data.source === 'Private') {
    source.textContent = 'Private Keybox';
    source.className = 'keybox-chip keybox-chip--neutral';
    icon.textContent = 'lock';
  } else if (data.source) {
    const name = data.source.charAt(0).toUpperCase() + data.source.slice(1);
    const label = data.text ? `${name} ${data.text}` : name;
    if (data.up_to_date) {
      source.textContent = label + ' \u00B7 Latest';
      source.className = 'keybox-chip keybox-chip--latest';
      icon.textContent = 'verified_user';
    } else {
      source.textContent = label;
      source.className = 'keybox-chip keybox-chip--outdated';
      icon.textContent = 'system_update';
    }
  } else {
    source.textContent = 'Generic';
    source.className = 'keybox-chip keybox-chip--neutral';
    icon.textContent = 'key';
  }

  if (data.revoked) {
    statusEl.textContent = 'Revoked';
    statusEl.className = 'keybox-chip keybox-chip--revoked';
    source.className = 'keybox-chip keybox-chip--revoked';
    icon.textContent = 'gpp_bad';
  } else {
    statusEl.textContent = 'Active';
    statusEl.className = 'keybox-chip keybox-chip--active';
  }
}

function setText(id: string, value: string) {
  const el = document.getElementById(id);
  if (el) el.textContent = value;
}

export async function loadBlacklistContent(): Promise<string> {
  try {
    const result = await exec('cat /data/adb/Specter/blacklist.txt 2>/dev/null || echo ""');
    return (result as any).stdout || '';
  } catch (e) { console.warn('Failed to load blacklist:', e); return ''; }
}

export async function loadSmartmergeContent(): Promise<string> {
  try {
    const result = await exec('cat /sdcard/Specter/customize.txt 2>/dev/null || echo ""');
    return (result as any).stdout || '';
  } catch (e) { console.warn('Failed to load smartmerge:', e); return ''; }
}

export async function saveBlacklistContent(content: string) {
  const result = await exec(`printf '%s' ${shellEscape(content)} | base64 -w0`);
  const b64 = (result as any).stdout || '';
  await exec(`mkdir -p /data/adb/Specter && printf '%s' "${b64}" | base64 -d > /data/adb/Specter/blacklist.txt`);
}

export async function saveSmartmergeContent(content: string) {
  const result = await exec(`printf '%s' ${shellEscape(content)} | base64 -w0`);
  const b64 = (result as any).stdout || '';
  await exec(`mkdir -p /sdcard/Specter && printf '%s' "${b64}" | base64 -d > /sdcard/Specter/customize.txt`);
}
