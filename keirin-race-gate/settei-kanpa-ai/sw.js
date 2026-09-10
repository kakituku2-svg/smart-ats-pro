const CACHE='settei-kanpa-v4-3-0-onebar';
const ASSETS=['./','./index.html','./app-v4.2.part1.txt','./app-v4.2.part2.txt','./app-v4.2.part3.txt','./app-v4.2.part4.txt','./app-v4.2.part5.txt','./app-v4.2.part6a.txt','./app-v4.2.part6b.txt','./app-v4.2.part6c.txt','./app-v4.2.part6d.txt','./manifest.webmanifest','./icon.svg'];
self.addEventListener('install',e=>e.waitUntil(caches.open(CACHE).then(c=>c.addAll(ASSETS)).then(()=>self.skipWaiting())));
self.addEventListener('activate',e=>e.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k!==CACHE).map(k=>caches.delete(k)))).then(()=>self.clients.claim())));
self.addEventListener('fetch',e=>{if(e.request.method!=='GET')return;e.respondWith(fetch(e.request).then(res=>{const cp=res.clone();caches.open(CACHE).then(c=>c.put(e.request,cp));return res;}).catch(()=>caches.match(e.request).then(r=>r||caches.match('./index.html'))))});
