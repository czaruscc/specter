let lastStatus = null;

export function initNetwork() {
  updateNetworkStatus();
  setInterval(updateNetworkStatus, 3000);
  window.addEventListener('online', updateNetworkStatus);
  window.addEventListener('offline', updateNetworkStatus);
}

export async function updateNetworkStatus() {
  const online = await checkOnline();

  if (online === lastStatus) return;
  const wasOnline = lastStatus;
  lastStatus = online;

  const statusCard  = document.getElementById('status-card');
  const statusIcon  = document.getElementById('status-icon');
  const statusValue = document.getElementById('status-value');
  const netChip     = document.getElementById('network-chip');
  const netChipText = netChip?.querySelector('span');

  const { getTranslation } = await import('./i18n.js');
  const onlineText  = getTranslation('home_status_online') || 'Online';
  const offlineText = getTranslation('home_status_offline') || 'Offline';

  if (online) {
    statusCard?.classList.remove('status-offline');
    if (statusIcon)  statusIcon.name = 'wifi';
    if (statusValue) statusValue.textContent = onlineText;
    if (netChipText) netChipText.textContent = onlineText;
    netChip?.classList.remove('offline');
    if (netChip) netChip.icon = 'wifi';
  } else {
    statusCard?.classList.add('status-offline');
    if (statusIcon)  statusIcon.name = 'wifi_off';
    if (statusValue) statusValue.textContent = offlineText;
    if (netChipText) netChipText.textContent = offlineText;
    netChip?.classList.add('offline');
    if (netChip) netChip.icon = 'wifi_off';

    if (wasOnline === true) {
      mdui.snackbar({ message: offlineText });
    }
  }
}

const ONLINE_ENDPOINTS = [
  'https://clients3.google.com/generate_204',
  'https://www.gstatic.com/generate_204',
];

async function checkOnline() {
  if (!navigator.onLine) return false;
  for (const endpoint of ONLINE_ENDPOINTS) {
    try {
      const ctrl = new AbortController();
      const timer = setTimeout(() => ctrl.abort(), 2000);
      await fetch(endpoint, { signal: ctrl.signal, mode: 'no-cors' });
      clearTimeout(timer);
      return true;
    } catch { /* try next endpoint */ }
  }
  return false;
}
