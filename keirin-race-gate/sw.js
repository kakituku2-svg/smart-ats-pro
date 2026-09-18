// KEIRIN RACE GATE v5.13.0 — iOS-safe network-first PWA cache
const CACHE="keirin-race-gate-v5.13.0-r2";
const PREFIXES=["keirin-race-gate-","keirin-race-gate-prediction-"];
const ASSETS=[
  "./",
  "./index.html",
  "./manifest.webmanifest",
  "./icon.svg",
  "./premium-ui-v580.css?rev=5.13.0-r2",
  "./premium-ui-v580.js?rev=5.13.0-r2",
  "./tail-risk-v5.js?rev=5.13.0-r2",
  "./tail-risk-v5-base.js?rev=5.8.0-base",
  "./human-context-v58.js?rev=5.13.0-r2"
];

self.addEventListener("install",e=>{
  e.waitUntil(
    caches.open(CACHE)
      .then(c=>c.addAll(ASSETS))
      .then(()=>self.skipWaiting())
  );
});

self.addEventListener("activate",e=>{
  e.waitUntil(
    caches.keys()
      .then(keys=>Promise.all(keys
        .filter(k=>k!==CACHE && PREFIXES.some(p=>k.startsWith(p)))
        .map(k=>caches.delete(k))))
      .then(()=>self.clients.claim())
  );
});

self.addEventListener("message",e=>{
  if(e.data==="SKIP_WAITING") self.skipWaiting();
});

self.addEventListener("fetch",e=>{
  if(e.request.method!=="GET") return;
  const isNav=e.request.mode==="navigate";
  if(isNav){
    e.respondWith(
      fetch(e.request,{cache:"no-store"})
        .then(async r=>{
          const copy=r.clone();
          const c=await caches.open(CACHE);
          await c.put(e.request,copy);
          return r;
        })
        .catch(async()=>{
          return (await caches.match(e.request)) ||
                 (await caches.match("./index.html")) ||
                 (await caches.match("./"));
        })
    );
    return;
  }
  e.respondWith(
    fetch(e.request,{cache:"no-store"})
      .then(r=>{
        const copy=r.clone();
        caches.open(CACHE).then(c=>c.put(e.request,copy));
        return r;
      })
      .catch(()=>caches.match(e.request))
  );
});
