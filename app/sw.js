importScripts('/app/version.js');
const VERSION = 'modox-' + self.MODOX_VERSION;
const SHELL = [
  '/app/',
  '/app/index.html',
  '/app/manifest.webmanifest',
  '/app/version.js',
  '/app/supabase.min.js',
  '/app/qrcode.min.js',
  '/img/icon-192.png',
  '/img/icon-512.png',
  '/img/modox-x.svg'
];

self.addEventListener('install', event => {
  event.waitUntil(caches.open(VERSION).then(cache => cache.addAll(SHELL)));
});

self.addEventListener('message', event => {
  if(event.data?.tipo === 'ATUALIZAR_AGORA') self.skipWaiting();
});

self.addEventListener('push', event => {
  let data={};
  try{data=event.data?.json()||{}}catch{data={texto:event.data?.text()||'Há uma nova interação no MODOX.'}}
  event.waitUntil(self.registration.showNotification(data.titulo||'MODOX',{
    body:data.texto||'Há uma nova interação aguardando você.',
    icon:'/img/icon-192.png',badge:'/img/icon-192.png',
    data:{url:'/app/',conversa_id:data.conversa_id||null},tag:data.conversa_id?`conversa-${data.conversa_id}`:'modox',
  }));
});

self.addEventListener('notificationclick', event => {
  event.notification.close();
  event.waitUntil(clients.matchAll({type:'window',includeUncontrolled:true}).then(janelas=>{
    const aberta=janelas.find(c=>c.url.startsWith(self.location.origin+'/app/'));
    return aberta?aberta.focus():clients.openWindow('/app/');
  }));
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
