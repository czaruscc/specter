if (typeof window.ksu === 'undefined') {
  const ksuMock = {
    exec(cmd: string, opts: string, cbName: string) {
      setTimeout(() => {
        const cb = window[cbName] as ((...args: any[]) => void) | undefined;
        if (typeof cb === 'function') cb(0, '', '');
      }, 50);
    },
    spawn(cmd: string, argsJson: string, opts: string, spName: string) {
      const child = window[spName] as any;
      if (child) {
        setTimeout(() => {
          child.stdout?.emit?.('data', '');
          child.emit?.('exit', 0);
        }, 100);
      }
    },
  };

  Object.defineProperty(window, 'ksu', {
    get() { return ksuMock; },
    configurable: true,
  });

  const origFetch = window.fetch.bind(window);
  window.fetch = function (url: RequestInfo | URL, ...rest: any[]) {
    const u = typeof url === 'string' ? url : (url as Request).url;

    if (u.startsWith('/json/module_paths.json')) {
      return origFetch(u, ...rest).then((r: Response) => {
        const ct = r.headers.get('content-type') || '';
        if (!r.ok || !ct.includes('json')) throw new Error('not found');
        return r;
      }).catch(() =>
        Promise.resolve(new Response(JSON.stringify({ MODDIR: '/data/adb/modules/Yurikey' }), {
          status: 200, headers: { 'Content-Type': 'application/json' },
        }))
      );
    }

    if (u.includes('/json/info.json')) {
      return Promise.resolve(new Response(JSON.stringify({
        android: '14', kernel: '6.1.0', root: 'KernelSU',
      }), { status: 200, headers: { 'Content-Type': 'application/json' } }));
    }

    return origFetch(u, ...rest);
  };
}

export {};
