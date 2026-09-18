from pathlib import Path
import re
import shutil

import build_keirin_v511 as base

ROOT = Path(__file__).resolve().parents[2]
SITE = ROOT / "_site"
VERSION = "5.13.0"
REV = "5.13.0-r2"
CACHE = "keirin-race-gate-v5.13.0-r2"

SW = r'''// KEIRIN RACE GATE v5.13.0 — iOS-safe network-first PWA cache
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
  const url=new URL(e.request.url);
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
'''


def patch_text_versions(text: str) -> str:
    text = re.sub(r"v5\.(?:7|8|9|10|11|12)\.0", "v5.13.0", text)
    return text


def patch_index(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    text = patch_text_versions(text)
    text = text.replace(
        "<!-- KEIRIN RACE GATE v5.13.0 Premium PWA -->",
        "<!-- KEIRIN RACE GATE v5.13.0 Premium PWA / iOS cache reset r2 -->",
    )
    text = re.sub(
        r'premium-ui-v580\.css\?rev=[^"\']+',
        f"premium-ui-v580.css?rev={REV}",
        text,
    )
    text = re.sub(
        r'tail-risk-v5\.js\?rev=[^"\']+',
        f"tail-risk-v5.js?rev={REV}",
        text,
    )
    text = re.sub(
        r'human-context-v58\.js\?rev=[^"\']+',
        f"human-context-v58.js?rev={REV}",
        text,
    )
    text = re.sub(
        r'premium-ui-v580\.js\?rev=[^"\']+',
        f"premium-ui-v580.js?rev={REV}",
        text,
    )
    path.write_text(text, encoding="utf-8")


def patch_premium_js(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    text = re.sub(r"const UI_VERSION = '[^']+';", "const UI_VERSION = '5.13.0';", text)
    text = re.sub(r"const LOGIC_VERSION = '[^']+';", "const LOGIC_VERSION = '5.13.0';", text)
    text = re.sub(
        r"if\(badge\) badge\.innerHTML='<i></i>v[^']+';",
        "if(badge) badge.innerHTML='<i></i>v5.13.0 · COMMENT HISTORY / HUMAN FACTOR';",
        text,
    )
    path.write_text(text, encoding="utf-8")


def patch_human_js(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    text = text.replace("const VERSION = '5.11.0';", "const VERSION = '5.13.0';")
    text = text.replace("v5.11.0", "v5.13.0")
    path.write_text(text, encoding="utf-8")


def patch_manifest(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    text = re.sub(r'"start_url"\s*:\s*"[^"]+"', '"start_url": "./?release=513-r2"', text)
    if '"id"' not in text:
        text = text.replace('"start_url": "./?release=513-r2",', '"id": "./",\n  "start_url": "./?release=513-r2",')
    path.write_text(text, encoding="utf-8")


def copy_nested() -> None:
    nested = SITE / "keirin-race-gate"
    nested.mkdir(parents=True, exist_ok=True)
    for name in [
        "index.html",
        "manifest.webmanifest",
        "icon.svg",
        "sw.js",
        "tail-risk-v5.js",
        "tail-risk-v5-base.js",
        "human-context-v58.js",
        "premium-ui-v580.css",
        "premium-ui-v580.js",
    ]:
        src = SITE / name
        if src.exists():
            shutil.copy2(src, nested / name)


def make_standalone() -> None:
    index = (SITE / "index.html").read_text(encoding="utf-8")
    css = (SITE / "premium-ui-v580.css").read_text(encoding="utf-8")
    tail = (SITE / "tail-risk-v5.js").read_text(encoding="utf-8")
    human = (SITE / "human-context-v58.js").read_text(encoding="utf-8")
    premium = (SITE / "premium-ui-v580.js").read_text(encoding="utf-8")

    index = re.sub(
        r'<link rel="stylesheet" href="\./premium-ui-v580\.css[^>]*>',
        lambda _: "<style>" + css + "</style>",
        index,
    )
    index = re.sub(
        r'<script src="\./tail-risk-v5\.js[^>]*></script>',
        lambda _: "<script>" + tail + "</script>",
        index,
    )
    index = re.sub(
        r'<script src="\./human-context-v58\.js[^>]*></script>',
        lambda _: "<script>" + human + "</script>",
        index,
    )
    index = re.sub(
        r'<script src="\./premium-ui-v580\.js[^>]*></script>',
        lambda _: "<script>" + premium + "</script>",
        index,
    )
    index = index.replace('<link rel="manifest" href="./manifest.webmanifest" />', "")
    index = index.replace("navigator.serviceWorker.register('./sw.js')", "Promise.resolve()")

    out = SITE / "downloads" / f"KEIRIN-RACE-GATE-v{VERSION}-Standalone.html"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(index, encoding="utf-8")


def validate() -> None:
    index = (SITE / "index.html").read_text(encoding="utf-8")
    nested = (SITE / "keirin-race-gate" / "index.html").read_text(encoding="utf-8")
    tail = (SITE / "tail-risk-v5.js").read_text(encoding="utf-8")
    sw = (SITE / "sw.js").read_text(encoding="utf-8")
    manifest = (SITE / "manifest.webmanifest").read_text(encoding="utf-8")
    standalone = (SITE / "downloads" / f"KEIRIN-RACE-GATE-v{VERSION}-Standalone.html").read_text(encoding="utf-8")

    required = [
        "COMMENT_HISTORY_MATCH_V513",
        "EMOTION_BEHAVIOR_BENEFIT_TRANSFER_V513",
        "RECENT_FIVE_RACE_TACTICAL_FORM_V513",
        "STYLE_COMPOSITION_COMPATIBILITY_V513",
        "MARKET_DISAGREEMENT_AUDIT_V513",
        "HEAD_RISE_REBUILD_V513",
        "HEAD_RISE_SOLO_AXIS_SURVIVAL_AUDIT_V513",
        "CANDIDATE_TO_COMBINATION_COMPLETENESS_V513",
        "AXIS_PARTIAL_SURVIVAL_V513",
        "COLLAPSE_THIRD_SURVIVOR_V513",
    ]
    missing = [x for x in required if x not in tail or x not in standalone]
    checks = [
        ("v5.13.0" in index, "root v5.13 marker"),
        ("v5.13.0" in nested, "nested v5.13 marker"),
        (CACHE in sw, "v5.13 service-worker cache"),
        ("release=513-r2" in manifest, "iOS manifest cache-bust"),
        ((SITE / "ai-seisaku-kobo" / "index.html").exists(), "AI Kobo preserved"),
    ]
    failed = [name for ok, name in checks if not ok]
    if missing or failed:
        problems = []
        if missing:
            problems.append("missing logic: " + ", ".join(missing))
        if failed:
            problems.append("failed checks: " + ", ".join(failed))
        raise SystemExit("; ".join(problems))


def main() -> None:
    # Reuse the proven iPhone/mobile layout build, then promote the generated
    # Pages bundle to the current v5.13 prediction engine and cache namespace.
    base.main()

    patch_index(SITE / "index.html")
    patch_premium_js(SITE / "premium-ui-v580.js")
    patch_human_js(SITE / "human-context-v58.js")
    patch_manifest(SITE / "manifest.webmanifest")
    (SITE / "sw.js").write_text(SW, encoding="utf-8")

    copy_nested()
    make_standalone()

    (SITE / "404.html").write_text(
        '<!doctype html><html lang="ja"><head><meta charset="utf-8">'
        '<meta name="viewport" content="width=device-width,initial-scale=1">'
        '<title>KEIRIN RACE GATE</title>'
        '<script>location.replace("/smart-ats-pro/keirin-race-gate/?release=513-r2");</script>'
        '</head><body></body></html>',
        encoding="utf-8",
    )

    validate()
    print(SITE)


if __name__ == "__main__":
    main()
