const VERSION = 'modox-1.1.0';
const SHELL = [
  '/app/',
  '/app/index.html',
  '/app/manifest.webmanifest',
  '/img/icon-192.png',
  '/img/icon-512.png',
  '/img/modox-x.svg'
];

self.addEventListener('install', event => {
  self.skipWaiting();
  event.waitUntil(caches.open(VERSION).then(cache => cache.addAll(SHELL)));
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(key => key !== VERSION).map(key => caches.delete(key))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', event => {
  const request = event.request;
  if(request.method !== 'GET') return;

  const url = new URL(request.url);
  if(url.origin !== self.location.origin) return;

  if(request.mode === 'navigate'){
    event.respondWith(
      fetch(request)
        .then(response => {
          if(response.ok){
            const copy = response.clone();
            caches.open(VERSION).then(cache => cache.put('/app/index.html', copy));
          }
          return response;
        })
        .catch(() => caches.match('/app/index.html'))
    );
    return;
  }

  event.respondWith(
    caches.match(request).then(cached => cached || fetch(request))
  );
});
