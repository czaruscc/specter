export function wireTopBarScroll() {
  const topBar = document.getElementById('top-bar');
  if (!topBar) return;
  window.addEventListener('scroll', () => {
    topBar.classList.toggle('app-top-bar--scrolled', window.scrollY > 0);
  });
}

export function wireNavigation() {
  const navTabs = document.querySelectorAll('.nav-tab');
  const indicator = document.getElementById('nav-indicator')!;
  const pageIds = ['home-page', 'tools-page', 'control-page', 'settings-page'];
  const pages = pageIds.map(id => document.getElementById(id)!).filter(Boolean);

  let lastClickTab: string | null = null;
  let clickTimer: ReturnType<typeof setTimeout> | null = null;

  function reposition(tab: HTMLElement) {
    indicator.style.left = tab.offsetLeft + 'px';
    indicator.style.width = tab.offsetWidth + 'px';
  }

  function activateTab(tab: HTMLElement) {
    const oldTab = document.querySelector('.nav-tab--active');
    if (oldTab && oldTab !== tab) {
      oldTab.classList.remove('nav-tab--active');
      oldTab.removeAttribute('aria-current');
      oldTab.querySelector('.nav-icon')?.classList.remove('nav-icon--filled');
    }
    tab.classList.add('nav-tab--active');
    tab.setAttribute('aria-current', 'page');
    tab.querySelector('.nav-icon')?.classList.add('nav-icon--filled');
    reposition(tab);
    const pageId = tab.dataset.page || '';
    pages.forEach((el) => { el.hidden = el.id !== pageId; });
    const hash = pageId.replace('-page', '');
    if (location.hash !== `#${hash}`) history.pushState(null, '', `#${hash}`);
  }

  function navigateTo(hash: string) {
    const target = hash.replace('#', '') + '-page';
    const tab = Array.from(navTabs).find(t => (t as HTMLElement).dataset.page === target) as HTMLElement | null;
    if (tab && !tab.classList.contains('nav-tab--active')) activateTab(tab);
  }

  navTabs.forEach((tab) => {
    tab.addEventListener('click', () => {
      const pageId = (tab as HTMLElement).dataset.page || '';
      if (lastClickTab === pageId) {
        window.scrollTo({ top: 0, behavior: 'smooth' });
        lastClickTab = null;
        if (clickTimer) clearTimeout(clickTimer);
        clickTimer = null;
      } else {
        lastClickTab = pageId;
        activateTab(tab as HTMLElement);
        clickTimer = setTimeout(() => {
          lastClickTab = null;
          clickTimer = null;
        }, 400);
      }
    });
  });

  window.addEventListener('popstate', () => {
    navigateTo(location.hash || '#home');
  });

  window.addEventListener('resize', () => {
    const active = document.querySelector('.nav-tab--active') as HTMLElement | null;
    if (active) reposition(active);
  });

  requestAnimationFrame(() => {
    navigateTo('#home');
    const active = document.querySelector('.nav-tab--active') as HTMLElement | null;
    if (active) reposition(active);
  });
}
