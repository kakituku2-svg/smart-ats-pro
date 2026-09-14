from pathlib import Path
import re
import shutil

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "keirin-race-gate"
SITE = ROOT / "_site"
RELEASE = "5.11.0"
REV = "5.11.0-r3"

CSS_FIX = r'''

/* RELEASE_UI_V511_FIXES — mobile spacing / icon overlap / bottom-nav safe area */
.field::before{grid-column:1!important;grid-row:1/3!important;align-self:start!important;justify-self:start!important}
.field .field-copy{grid-column:2!important;min-width:0!important}
.field input,.field .native-select-wrap{grid-column:2!important;min-width:0!important}
#generate-button{display:grid!important;grid-template-columns:auto minmax(0,1fr) auto!important;align-items:center!important;gap:12px!important;padding:0 18px!important;margin-top:18px!important;margin-bottom:4px!important}
#generate-button::after{content:none!important;display:none!important}
#generate-button .button-icon{display:grid!important;place-items:center!important;width:28px!important;height:28px!important;flex:0 0 auto!important}
#generate-button .button-icon svg,#generate-button .button-arrow{display:block!important;width:22px!important;height:22px!important;fill:none!important;stroke:currentColor!important;stroke-width:1.8!important}
#generate-button>span:not(.button-icon){min-width:0!important;text-align:center!important;white-space:normal!important;line-height:1.35!important}
.round-button[aria-checked="true"]{color:#051421!important;background:linear-gradient(135deg,#66eaff,#37caff)!important;border-color:transparent!important;box-shadow:0 6px 20px rgba(57,223,255,.22)!important}
.field input[type="date"]{padding-right:12px!important}
.field input[type="date"]::-webkit-calendar-picker-indicator{margin-left:8px!important;opacity:.78!important}
.native-select-wrap select{padding-left:16px!important;padding-right:48px!important}
.select-chevron{right:16px!important;z-index:2!important}
main{padding-bottom:calc(132px + env(safe-area-inset-bottom))!important}
footer{padding-bottom:calc(128px + env(safe-area-inset-bottom))!important}
.premium-bottom-nav{bottom:max(10px,env(safe-area-inset-bottom))!important;width:min(520px,calc(100% - 20px))!important}
body.result-open .premium-bottom-nav{opacity:0!important;pointer-events:none!important;transform:translate(-50%,18px)!important}
.paper-badge{white-space:nowrap!important}
@media(max-width:720px){
  .site-header{padding-left:14px!important;padding-right:14px!important}
  .paper-badge{max-width:48vw!important;overflow:hidden!important;text-overflow:ellipsis!important}
  .hero{padding-bottom:24px!important}
  .composer-card{overflow:visible!important}
  .field{grid-template-columns:38px minmax(0,1fr)!important;padding:16px!important}
  .field::before{width:32px!important;height:32px!important}
  .field input,.native-select-wrap select{min-height:52px!important;font-size:16px!important}
  .round-grid{grid-template-columns:repeat(4,minmax(0,1fr))!important}
  #generate-button{min-height:64px!important;padding:0 16px!important;margin-top:20px!important}
  #generate-button .button-arrow{width:20px!important;height:20px!important}
  .premium-bottom-nav{border-radius:18px!important}
}
@media(max-width:380px){
  .brand-copy small{display:none!important}
  .paper-badge{font-size:7px!important;max-width:45vw!important}
  #generate-button{gap:8px!important;padding:0 12px!important;font-size:14px!important}
}
'''

SW = r'''// KEIRIN RACE GATE v5.11.0 — direct-asset PWA cache
const CACHE="keirin-race-gate-v5.11.0-r3";
const ASSETS=["./","./index.html","./manifest.webmanifest","./icon.svg","./premium-ui-v580.css?rev=5.11.0-r3","./premium-ui-v580.js?rev=5.11.0-r3","./tail-risk-v5.js?rev=5.7.0-r3","./human-context-v58.js?rev=5.11.0-r3"];
self.addEventListener("install",e=>e.waitUntil(caches.open(CACHE).then(c=>c.addAll(ASSETS)).then(()=>self.skipWaiting())));
self.addEventListener("activate",e=>e.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k!==CACHE).map(k=>caches.delete(k)))).then(()=>self.clients.claim())));
self.addEventListener("fetch",e=>{
  if(e.request.method!=="GET") return;
  const isNav=e.request.mode==="navigate";
  if(isNav){
    e.respondWith(fetch(e.request,{cache:"no-store"}).then(async r=>{const copy=r.clone();const c=await caches.open(CACHE);await c.put(e.request,copy);return r;}).catch(()=>caches.match(e.request).then(r=>r||caches.match("./index.html"))));
    return;
  }
  e.respondWith(fetch(e.request,{cache:"no-store"}).then(r=>{const copy=r.clone();caches.open(CACHE).then(c=>c.put(e.request,copy));return r;}).catch(()=>caches.match(e.request)));
});
'''


def patch_premium_css(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    if "RELEASE_UI_V511_FIXES" not in text:
        text += CSS_FIX
    path.write_text(text, encoding="utf-8")


def patch_premium_js(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    text = text.replace("const UI_VERSION = '5.8.0';", "const UI_VERSION = '5.11.0';")
    text = text.replace("const LOGIC_VERSION = '5.10.0';", "const LOGIC_VERSION = '5.11.0';")
    text = text.replace(
        "if(badge) badge.innerHTML='<i></i>v5.8.0 · LIVE DATA / EV';",
        "if(badge) badge.innerHTML='<i></i>v5.11.0 · HUMAN CONTEXT / EV';",
    )
    old = "if(!/AI予想プロンプトを生成/.test(submit.textContent||'')) submit.textContent='AI予想プロンプトを生成';"
    new = "const label=[...submit.querySelectorAll('span')].find(x=>!x.classList.contains('button-icon')); if(label){ label.textContent='AI予想プロンプトを生成'; } else if(!/AI予想プロンプトを生成/.test(submit.textContent||'')){ submit.textContent='AI予想プロンプトを生成'; }"
    text = text.replace(old, new)
    path.write_text(text, encoding="utf-8")


def patch_index(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    text = text.replace(
        "<!-- KEIRIN AI RACE GATE v5.7.0 iPhone PWA -->",
        "<!-- KEIRIN RACE GATE v5.11.0 Premium PWA -->",
    )
    text = text.replace(
        '<span class="paper-badge"><i></i>v5.7.0 · LIVE DATA / EV</span>',
        '<span class="paper-badge"><i></i>v5.11.0 · HUMAN CONTEXT / EV</span>',
    )
    text = text.replace(
        '<small>v5.7.0 · 20歳以上 / 予想支援ツール</small>',
        '<small>v5.11.0 · DUAL WHEEL / COLLAPSE AUDIT · 20歳以上 / 予想支援ツール</small>',
    )
    text = text.replace("AI予想プロンプト · v5.7.0", "AI予想プロンプト · v5.11.0")
    text = text.replace("実戦予想 v5.7.0", "実戦予想 v5.11.0")
    text = text.replace('var SPEC_VERSION = "5.7.0";', 'var SPEC_VERSION = "5.11.0";')
    text = text.replace('"  version: \\"5.7.0\\";",', '"  version: \\"5.11.0\\";",')

    css = f'<link rel="stylesheet" href="./premium-ui-v580.css?rev={REV}" />'
    if "premium-ui-v580.css" not in text:
        text = text.replace("</head>", css + "\n</head>")
    else:
        text = re.sub(r'<link rel="stylesheet" href="\./premium-ui-v580\.css[^>]*>', css, text)

    tail = '<script src="./tail-risk-v5.js?rev=5.7.0-r3"></script>'
    human = f'<script src="./human-context-v58.js?rev={REV}"></script>'
    premium = f'<script src="./premium-ui-v580.js?rev={REV}"></script>'
    text = re.sub(r'\s*<script src="\./tail-risk-v5\.js[^>]*></script>\s*', "\n" + tail + "\n", text)
    text = re.sub(r'\s*<script src="\./human-context-v58\.js[^>]*></script>\s*', "\n", text)
    text = re.sub(r'\s*<script src="\./premium-ui-v580\.js[^>]*></script>\s*', "\n", text)
    text = text.replace("</body>", human + "\n" + premium + "\n</body>")
    path.write_text(text, encoding="utf-8")


def make_standalone() -> None:
    base = (SITE / "index.html").read_text(encoding="utf-8")
    css = (SITE / "premium-ui-v580.css").read_text(encoding="utf-8")
    tail = (SITE / "tail-risk-v5.js").read_text(encoding="utf-8")
    human = (SITE / "human-context-v58.js").read_text(encoding="utf-8")
    premium = (SITE / "premium-ui-v580.js").read_text(encoding="utf-8")
    base = re.sub(r'<link rel="stylesheet" href="\./premium-ui-v580\.css[^>]*>', lambda _: "<style>" + css + "</style>", base)
    base = re.sub(r'<script src="\./tail-risk-v5\.js[^>]*></script>', lambda _: "<script>" + tail + "</script>", base)
    base = re.sub(r'<script src="\./human-context-v58\.js[^>]*></script>', lambda _: "<script>" + human + "</script>", base)
    base = re.sub(r'<script src="\./premium-ui-v580\.js[^>]*></script>', lambda _: "<script>" + premium + "</script>", base)
    base = base.replace('<link rel="manifest" href="./manifest.webmanifest" />', "")
    base = base.replace("navigator.serviceWorker.register('./sw.js')", "Promise.resolve()")
    out = SITE / "downloads" / "KEIRIN-RACE-GATE-v5.11.0-Standalone.html"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(base, encoding="utf-8")


def validate() -> None:
    index = (SITE / "index.html").read_text(encoding="utf-8")
    css = (SITE / "premium-ui-v580.css").read_text(encoding="utf-8")
    premium = (SITE / "premium-ui-v580.js").read_text(encoding="utf-8")
    human = (SITE / "human-context-v58.js").read_text(encoding="utf-8")
    sw = (SITE / "sw.js").read_text(encoding="utf-8")
    checks = [
        ("KEIRIN RACE GATE v5.11.0 Premium PWA" in index, "release marker"),
        (f"premium-ui-v580.css?rev={REV}" in index, "premium css link"),
        (f"human-context-v58.js?rev={REV}" in index, "human script link"),
        (f"premium-ui-v580.js?rev={REV}" in index, "premium js link"),
        ("RELEASE_UI_V511_FIXES" in css, "UI fix marker"),
        ("const UI_VERSION = '5.11.0'" in premium, "premium UI version"),
        ("DUAL_WHEEL_REVERSAL_AUDIT_V511" in human, "dual-wheel audit"),
        ("SELF_AUDIT_LOGIC_V511" in human, "self audit"),
        ("COLLAPSE_THIRD_SURVIVOR_AUDIT_V511" in human, "collapse survivor audit"),
        ("TAIL_RISK_THIRD_SURVIVOR_V511" in human, "tail-risk survivor audit"),
        ("keirin-race-gate-v5.11.0-r3" in sw, "service-worker cache"),
    ]
    failed = [name for ok, name in checks if not ok]
    if failed:
        raise SystemExit("Validation failed: " + ", ".join(failed))


def main() -> None:
    if SITE.exists():
        shutil.rmtree(SITE)
    shutil.copytree(SRC, SITE)
    (SITE / "downloads").mkdir(parents=True, exist_ok=True)

    patch_premium_css(SITE / "premium-ui-v580.css")
    patch_premium_js(SITE / "premium-ui-v580.js")
    patch_index(SITE / "index.html")
    (SITE / "sw.js").write_text(SW, encoding="utf-8")

    nested = SITE / "keirin-race-gate"
    nested.mkdir(parents=True, exist_ok=True)
    for name in [
        "index.html",
        "manifest.webmanifest",
        "icon.svg",
        "sw.js",
        "tail-risk-v5.js",
        "human-context-v58.js",
        "premium-ui-v580.css",
        "premium-ui-v580.js",
    ]:
        src = SITE / name
        if src.exists():
            shutil.copy2(src, nested / name)

    make_standalone()
    (SITE / "404.html").write_text(
        '<!doctype html><html lang="ja"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>KEIRIN RACE GATE</title><script>location.replace(\'/smart-ats-pro/\'+location.search+location.hash);</script></head><body></body></html>',
        encoding="utf-8",
    )
    validate()


if __name__ == "__main__":
    main()
