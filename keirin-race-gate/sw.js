// KEIRIN RACE GATE — UI v5.8.0 / prediction engine v5.12.0
const CACHE="keirin-race-gate-prediction-v5.12.0-r1";
const ASSETS=[
  "./",
  "./index.html",
  "./manifest.webmanifest",
  "./icon.svg",
  "./premium-ui-v580.css?rev=5.8.0-r1",
  "./premium-ui-v580.js?rev=5.8.0-r1",
  "./tail-risk-v5.js?rev=5.12.0-r1",
  "./human-context-v58.js?rev=5.10.0-r1"
];

self.addEventListener("install",e=>{
  e.waitUntil(caches.open(CACHE).then(c=>c.addAll(ASSETS)).then(()=>self.skipWaiting()));
});

self.addEventListener("activate",e=>{
  e.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k!==CACHE).map(k=>caches.delete(k)))).then(()=>self.clients.claim()));
});

async function injectLayers(response){
  const type=response.headers.get("content-type")||"";
  if(!type.includes("text/html")) return response;
  let html=await response.text();
  if(!html.includes("premium-ui-v580.css")) html=html.replace("</head>",'<link rel="stylesheet" href="./premium-ui-v580.css?rev=5.8.0-r1"></head>');
  const scripts=[];
  if(!html.includes("tail-risk-v5.js")) scripts.push('<script src="./tail-risk-v5.js?rev=5.12.0-r1"></script>');
  if(!html.includes("human-context-v58.js")) scripts.push('<script src="./human-context-v58.js?rev=5.10.0-r1"></script>');
  if(!html.includes("premium-ui-v580.js")) scripts.push('<script src="./premium-ui-v580.js?rev=5.8.0-r1"></script>');
  if(scripts.length) html=html.replace("</body>",scripts.join("")+"</body>");
  const headers=new Headers(response.headers);
  headers.delete("content-length");
  return new Response(html,{status:response.status,statusText:response.statusText,headers});
}

self.addEventListener("fetch",e=>{
  if(e.request.method!=="GET") return;
  const url=new URL(e.request.url);
  const isNavigation=e.request.mode==="navigate" || url.pathname.endsWith("/smart-ats-pro/") || url.pathname.endsWith("/index.html") || url.pathname.endsWith("/keirin-race-gate/");
  if(isNavigation){
    e.respondWith(fetch(e.request,{cache:"no-store"}).then(r=>injectLayers(r)).then(async r=>{const copy=r.clone();const c=await caches.open(CACHE);await c.put(e.request,copy);return r;}).catch(async()=>{const cached=await caches.match(e.request)||await caches.match("./index.html");return cached ? injectLayers(cached.clone()) : cached;}));
    return;
  }
  e.respondWith(fetch(e.request,{cache:"no-store"}).then(r=>{const copy=r.clone();caches.open(CACHE).then(c=>c.put(e.request,copy));return r;}).catch(()=>caches.match(e.request)));
});
