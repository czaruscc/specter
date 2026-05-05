let clockInterval: ReturnType<typeof setInterval> | null = null;

export async function initClock() {
  updateClock();
  clockInterval = setInterval(updateClock, 1000);
  window.addEventListener('beforeunload', destroyClock);
}

function destroyClock() {
  if (clockInterval) {
    clearInterval(clockInterval);
    clockInterval = null;
  }
}

function updateClock() {
  const now = new Date();
  const dateEl = document.getElementById('clock-date');
  const timeEl = document.getElementById('clock-time');

  if (dateEl) dateEl.textContent = now.toLocaleDateString();
  if (timeEl) timeEl.textContent = now.toLocaleTimeString();
}
