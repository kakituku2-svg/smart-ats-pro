from pathlib import Path
import re, shutil

ROOT=Path(__file__).resolve().parents[2]
SRC=ROOT/'keirin-race-gate'
SITE=ROOT/'_site'
VERSION='5.13.0'


def main():
    if SITE.exists(): shutil.rmtree(SITE)
    shutil.copytree(SRC,SITE)
    (SITE/'downloads').mkdir(parents=True,exist_ok=True)
    index=(SITE/'index.html').read_text(encoding='utf-8')
    css=(SITE/'premium-ui-v580.css').read_text(encoding='utf-8')
    tail=(SITE/'tail-risk-v5.js').read_text(encoding='utf-8')
    human=(SITE/'human-context-v58.js').read_text(encoding='utf-8')
    premium=(SITE/'premium-ui-v580.js').read_text(encoding='utf-8')
    index=re.sub(r'<link rel="stylesheet" href="\./premium-ui-v580\.css[^>]*>',lambda _: '<style>'+css+'</style>',index)
    index=re.sub(r'<script src="\./tail-risk-v5\.js[^>]*></script>',lambda _: '<script>'+tail+'</script>',index)
    index=re.sub(r'<script src="\./human-context-v58\.js[^>]*></script>',lambda _: '<script>'+human+'</script>',index)
    index=re.sub(r'<script src="\./premium-ui-v580\.js[^>]*></script>',lambda _: '<script>'+premium+'</script>',index)
    index=index.replace('<link rel="manifest" href="./manifest.webmanifest" />','')
    index=index.replace("navigator.serviceWorker.register('./sw.js')","Promise.resolve()")
    index=re.sub(r'v5\.(?:10|11|12)\.0','v5.13.0',index)
    out=SITE/'downloads'/f'KEIRIN-RACE-GATE-v{VERSION}-Standalone.html'
    out.write_text(index,encoding='utf-8')
    text=out.read_text(encoding='utf-8')
    required=['COMMENT_HISTORY_MATCH_V513','EMOTION_BEHAVIOR_BENEFIT_TRANSFER_V513','RECENT_FIVE_RACE_TACTICAL_FORM_V513','STYLE_COMPOSITION_COMPATIBILITY_V513','MARKET_DISAGREEMENT_AUDIT_V513','HEAD_RISE_REBUILD_V513','CANDIDATE_TO_COMBINATION_COMPLETENESS_V513','AXIS_PARTIAL_SURVIVAL_V513','COLLAPSE_THIRD_SURVIVOR_V513']
    missing=[x for x in required if x not in text]
    if missing: raise SystemExit('Missing v5.13 logic: '+', '.join(missing))
    print(out)

if __name__=='__main__': main()
