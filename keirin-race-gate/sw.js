const CACHE="keirin-race-gate-v5.1.0";
const ASSETS=["./","./index.html","./manifest.webmanifest","./icon.svg","./tail-risk-v5.js"];

self.addEventListener("install",e=>{
  e.waitUntil(caches.open(CACHE).then(c=>c.addAll(ASSETS)).then(()=>self.skipWaiting()));
});

self.addEventListener("activate",e=>{
  e.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k!==CACHE).map(k=>caches.delete(k)))).then(()=>self.clients.claim()));
});

async function injectTailRisk(response){
  const type=response.headers.get("content-type")||"";
  if(!type.includes("text/html")) return response;
  let html=await response.text();
  if(!html.includes("tail-risk-v5.js")){
    html=html.replace("</body>",'<script src="./tail-risk-v5.js"></script></body>');
  }
  const headers=new Headers(response.headers);
  headers.delete("content-length");
  return new Response(html,{status:response.status,statusText:response.statusText,headers});
}

self.addEventListener("fetch",e=>{
  if(e.request.method!=="GET") return;
  const url=new URL(e.request.url);
  const isNavigation=e.request.mode==="navigate" || url.pathname.endsWith("/keirin-race-gate/") || url.pathname.endsWith("/keirin-race-gate/index.html");

  if(isNavigation){
    e.respondWith(
      fetch(e.request)
        .then(r=>injectTailRisk(r))
        .then(async r=>{const copy=r.clone();const c=await caches.open(CACHE);await c.put(e.request,copy);return r;})
        .catch(async()=>{
          const cached=await caches.match(e.request)||await caches.match("./index.html");
          return cached ? injectTailRisk(cached.clone()) : cached;
        })
    );
    return;
  }

  e.respondWith(fetch(e.request).then(r=>{const copy=r.clone();caches.open(CACHE).then(c=>c.put(e.request,copy));return r;}).catch(()=>caches.match(e.request)));
});
