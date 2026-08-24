from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'android' / 'app' / 'src' / 'main' / 'assets'

def read(path):
    return path.read_text(encoding='utf-8')

index = read(ASSETS / 'index.html')
styles = read(ASSETS / 'styles.css')
core = read(ASSETS / 'core.js')
app = read(ASSETS / 'app.js')
ai = read(ASSETS / 'ai.js')
account = read(ASSETS / 'account.js')
vault = read(ASSETS / 'vault.js')
integrations = read(ASSETS / 'integrations.js')
workflow = read(ASSETS / 'workflow.js')
audit = read(ASSETS / 'audit.js')
onboarding = read(ASSETS / 'onboarding.js')
manifest = read(ROOT / 'android' / 'app' / 'src' / 'main' / 'AndroidManifest.xml')
java = read(ROOT / 'android' / 'app' / 'src' / 'main' / 'java' / 'jp' / 'smartats' / 'pro' / 'MainActivity.java')
build = read(ROOT / 'android' / 'app' / 'build.gradle')
assets_all='\n'.join(read(p) for p in ASSETS.iterdir() if p.is_file())

checks={
 'version-core': "VERSION='0.5.0'" in core,
 'version-app': "APP_VERSION = '0.5.0'" in app,
 'version-android': "versionName '0.5.0'" in build and 'versionCode 5' in build,
 'candidate-job-interview': all(x in index for x in ['candidateFormTemplate','jobFormTemplate','interviewFormTemplate']),
 'mobile-safe-area': 'viewport-fit=cover' in index and 'safe-area-inset-bottom' in styles,
 'local-backups': all(x in core for x in ['autoBackup.1','autoBackup.2','autoBackup.3','restoreLatestBackup']),
 'ai-files-linked': all(x in index for x in ['ai.js','workflow.js','audit.js','onboarding.js']),
 'ai-tools': all(x in ai for x in ['renderResume','renderScout','renderReply','renderSummary','renderQuestions','renderSettings']),
 'resume-types': all(x in ai for x in ['application/pdf','image/png','image/jpeg','inlineData']),
 'human-review-guard': '採用判断をAIへ委ねる機能ではありません' in ai and '自動送信することはありません' in ai,
 'account-local-first': all(x in account for x in ["mode:'local'","cloudEnabled:false","gmailMode:'system'","resumeOriginals:'off'"]),
 'optional-integrations': all(x in account for x in ['cloudProjectUrl','cloudAnonKey','gmailAccount','googleOAuthClientId']),
 'vault-native': all(x in java for x in ['DOC_KEY_ALIAS','AES/GCM/NoPadding','saveEncryptedDocument','listCandidateDocuments','deleteEncryptedDocument']),
 'vault-opt-in': 'local_vault' in vault and '10MB以下' in vault,
 'supabase-test': 'testSupabaseConnection' in java and '候補者データは送信していません' in java,
 'gmail-detection': 'isGmailInstalled' in java and 'com.google.android.gm' in java,
 'gemini-native': 'generativelanguage.googleapis.com' in java and 'generativelanguage.googleapis.com' not in assets_all,
 'gemini-keystore': all(x in java for x in ['AndroidKeyStore','saveEncryptedApiKey','loadEncryptedApiKey']),
 'internet-cleartext-guard': 'android.permission.INTERNET' in manifest and 'android:usesCleartextTraffic="false"' in manifest,
 'backup-disabled': 'android:allowBackup="false"' in manifest,
 'file-picker': 'onShowFileChooser' in java and 'ACTION_OPEN_DOCUMENT' in java,
 'external-nav-blocked': 'file:///android_asset/' in java and 'shouldOverrideUrlLoading' in java,
 'audit-minimal': 'const MAX=200' in audit and 'feature:feature||' in audit and 'ok:!!ok' in audit,
 'workflow-shortcuts': all(x in workflow for x in ['renderScout','renderReply','renderSummary','renderQuestions']),
 'no-hardcoded-google-api-key': re.search(r'AIza[0-9A-Za-z_-]{20,}', assets_all) is None,
 'release-signing-ready': all(x in build for x in ['SMART_ATS_KEYSTORE_PATH','SMART_ATS_KEYSTORE_PASSWORD','SMART_ATS_KEY_ALIAS','SMART_ATS_KEY_PASSWORD']),
}

failed=[]
for name,ok in checks.items():
    print(('PASS' if ok else 'FAIL'), name)
    if not ok: failed.append(name)

if failed:
    print('FAILED:', ', '.join(failed), file=sys.stderr)
    raise SystemExit(1)
print(f'PASS all {len(checks)} static checks')
