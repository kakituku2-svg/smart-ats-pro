package jp.smartats.pro;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Bundle;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;
import android.util.Base64;
import android.webkit.JavascriptInterface;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.security.KeyStore;
import java.util.UUID;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.regex.Pattern;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import javax.net.ssl.HttpsURLConnection;

public class MainActivity extends Activity {
    private static final String HOME_URL = "file:///android_asset/index.html";
    private static final int FILE_CHOOSER_REQUEST = 4107;
    private static final int MAX_DOCUMENT_BYTES = 10 * 1024 * 1024;

    private static final String PREFS = "smart_ats_private";
    private static final String PREF_API_KEY = "gemini_api_key_enc";
    private static final String PREF_MODEL = "gemini_model";
    private static final String PREF_DOC_META = "candidate_docs_meta_enc";

    private static final String KEY_ALIAS = "smart_ats_gemini_key";
    private static final String DOC_KEY_ALIAS = "smart_ats_document_key";
    private static final String DOC_DIR = "candidate_documents";
    private static final String DEFAULT_MODEL = "gemini-3.7-flash";

    private static final Pattern SAFE_MODEL = Pattern.compile("^[A-Za-z0-9._-]{3,80}$");
    private static final Pattern SAFE_ID = Pattern.compile("^[A-Za-z0-9_-]{1,120}$");
    private static final Pattern SUPABASE_URL = Pattern.compile("^https://[A-Za-z0-9.-]+\\.supabase\\.co/?$");

    private WebView webView;
    private ValueCallback<Uri[]> filePathCallback;
    private final ExecutorService networkExecutor = Executors.newSingleThreadExecutor();

    @SuppressLint({"SetJavaScriptEnabled", "JavascriptInterface"})
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        webView = new WebView(this);
        setContentView(webView);

        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setDatabaseEnabled(false);
        settings.setAllowFileAccess(true);
        settings.setAllowContentAccess(true);
        settings.setAllowFileAccessFromFileURLs(false);
        settings.setAllowUniversalAccessFromFileURLs(false);
        settings.setBuiltInZoomControls(false);
        settings.setDisplayZoomControls(false);
        settings.setTextZoom(100);
        settings.setSaveFormData(false);
        settings.setGeolocationEnabled(false);
        settings.setMediaPlaybackRequiresUserGesture(true);

        webView.addJavascriptInterface(new NativeBridge(this), "AndroidBridge");
        webView.setWebChromeClient(new WebChromeClient() {
            @Override
            public boolean onShowFileChooser(WebView view, ValueCallback<Uri[]> callback, FileChooserParams params) {
                if (filePathCallback != null) filePathCallback.onReceiveValue(null);
                filePathCallback = callback;
                Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
                intent.addCategory(Intent.CATEGORY_OPENABLE);
                intent.setType("*/*");
                intent.putExtra(Intent.EXTRA_MIME_TYPES, new String[]{"application/pdf", "image/png", "image/jpeg"});
                intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
                try {
                    startActivityForResult(intent, FILE_CHOOSER_REQUEST);
                    return true;
                } catch (Exception e) {
                    filePathCallback = null;
                    return false;
                }
            }
        });
        webView.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                String url = request.getUrl().toString();
                return !url.startsWith("file:///android_asset/");
            }

            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                return url == null || !url.startsWith("file:///android_asset/");
            }
        });
        webView.setVerticalScrollBarEnabled(false);
        webView.setHorizontalScrollBarEnabled(false);
        webView.setBackgroundColor(0xFFF3F5F9);
        WebView.setWebContentsDebuggingEnabled(BuildConfig.DEBUG);
        webView.loadUrl(HOME_URL);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode != FILE_CHOOSER_REQUEST || filePathCallback == null) return;
        Uri[] result = null;
        if (resultCode == Activity.RESULT_OK && data != null && data.getData() != null) {
            result = new Uri[]{data.getData()};
        }
        filePathCallback.onReceiveValue(result);
        filePathCallback = null;
    }

    @Override
    public void onBackPressed() {
        if (webView == null) {
            super.onBackPressed();
            return;
        }
        String script = "(function(){var p=document.getElementById('aiPanel');if(p&&window.SmartATSAI&&!p.classList.contains('hidden')){window.SmartATSAI.close();return '1';}if(window.SmartATS&&window.SmartATS.handleBack&&window.SmartATS.handleBack())return '1';return '0';})()";
        webView.evaluateJavascript(script, result -> {
            if (!"\"1\"".equals(result) && !"1".equals(result)) MainActivity.super.onBackPressed();
        });
    }

    @Override
    protected void onDestroy() {
        networkExecutor.shutdownNow();
        if (filePathCallback != null) {
            filePathCallback.onReceiveValue(null);
            filePathCallback = null;
        }
        if (webView != null) {
            webView.removeJavascriptInterface("AndroidBridge");
            webView.loadUrl("about:blank");
            webView.stopLoading();
            webView.clearHistory();
            webView.removeAllViews();
            webView.destroy();
            webView = null;
        }
        super.onDestroy();
    }

    private SharedPreferences prefs() {
        return getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }

    private SecretKey getOrCreateKey(String alias) throws Exception {
        KeyStore store = KeyStore.getInstance("AndroidKeyStore");
        store.load(null);
        if (!store.containsAlias(alias)) {
            KeyGenerator generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore");
            generator.init(new KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_ENCRYPT | KeyProperties.PURPOSE_DECRYPT)
                    .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                    .setRandomizedEncryptionRequired(true)
                    .build());
            generator.generateKey();
        }
        return ((KeyStore.SecretKeyEntry) store.getEntry(alias, null)).getSecretKey();
    }

    private String encryptString(String alias, String value) throws Exception {
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        cipher.init(Cipher.ENCRYPT_MODE, getOrCreateKey(alias));
        byte[] encrypted = cipher.doFinal(value.getBytes(StandardCharsets.UTF_8));
        return Base64.encodeToString(cipher.getIV(), Base64.NO_WRAP) + ":" + Base64.encodeToString(encrypted, Base64.NO_WRAP);
    }

    private String decryptString(String alias, String packed) throws Exception {
        if (packed == null || packed.isEmpty() || !packed.contains(":")) return "";
        String[] parts = packed.split(":", 2);
        byte[] iv = Base64.decode(parts[0], Base64.NO_WRAP);
        byte[] encrypted = Base64.decode(parts[1], Base64.NO_WRAP);
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        cipher.init(Cipher.DECRYPT_MODE, getOrCreateKey(alias), new GCMParameterSpec(128, iv));
        return new String(cipher.doFinal(encrypted), StandardCharsets.UTF_8);
    }

    private void saveEncryptedApiKey(String value) throws Exception {
        prefs().edit().putString(PREF_API_KEY, encryptString(KEY_ALIAS, value)).apply();
    }

    private String loadEncryptedApiKey() {
        try {
            return decryptString(KEY_ALIAS, prefs().getString(PREF_API_KEY, ""));
        } catch (Exception e) {
            return "";
        }
    }

    private JSONArray loadDocumentMeta() {
        try {
            String json = decryptString(DOC_KEY_ALIAS, prefs().getString(PREF_DOC_META, ""));
            return json.isEmpty() ? new JSONArray() : new JSONArray(json);
        } catch (Exception e) {
            return new JSONArray();
        }
    }

    private void saveDocumentMeta(JSONArray meta) throws Exception {
        prefs().edit().putString(PREF_DOC_META, encryptString(DOC_KEY_ALIAS, meta.toString())).apply();
    }

    private File documentDirectory() {
        File dir = new File(getFilesDir(), DOC_DIR);
        if (!dir.exists()) dir.mkdirs();
        return dir;
    }

    private String safeFileName(String name) {
        String value = name == null ? "document" : name.trim();
        value = value.replaceAll("[\\r\\n\\t\\u0000-\\u001f]", "_");
        if (value.length() > 140) value = value.substring(0, 140);
        return value.isEmpty() ? "document" : value;
    }

    private String errorJson(String message) {
        try {
            JSONObject error = new JSONObject();
            error.put("error", message == null || message.isEmpty() ? "保存に失敗しました" : message);
            return error.toString();
        } catch (Exception ignored) {
            return "{\"error\":\"保存に失敗しました\"}";
        }
    }

    private void callbackGemini(String callbackId, boolean ok, String payload) {
        if (webView == null) return;
        String js = "window.SmartATSAI&&window.SmartATSAI._nativeResult(" + JSONObject.quote(callbackId) + "," + (ok ? "true" : "false") + "," + JSONObject.quote(payload == null ? "" : payload) + ");";
        webView.post(() -> {
            if (webView != null) webView.evaluateJavascript(js, null);
        });
    }

    private void callbackIntegration(String callbackId, boolean ok, String payload) {
        if (webView == null) return;
        String js = "window.SmartATSIntegrations&&window.SmartATSIntegrations._nativeResult(" + JSONObject.quote(callbackId) + "," + (ok ? "true" : "false") + "," + JSONObject.quote(payload == null ? "" : payload) + ");";
        webView.post(() -> {
            if (webView != null) webView.evaluateJavascript(js, null);
        });
    }

    private String readStream(InputStream stream) throws Exception {
        if (stream == null) return "";
        StringBuilder out = new StringBuilder();
        try (BufferedReader br = new BufferedReader(new InputStreamReader(stream, StandardCharsets.UTF_8))) {
            String line;
            while ((line = br.readLine()) != null) out.append(line).append('\n');
        }
        return out.toString();
    }

    public class NativeBridge {
        private final Context context;
        NativeBridge(Context context) { this.context = context; }

        @JavascriptInterface
        public void copyText(String text) {
            ClipboardManager clipboard = (ClipboardManager) context.getSystemService(Context.CLIPBOARD_SERVICE);
            if (clipboard != null) clipboard.setPrimaryClip(ClipData.newPlainText("Smart ATS Pro", text == null ? "" : text));
        }

        @JavascriptInterface
        public void shareText(String subject, String text) {
            Intent intent = new Intent(Intent.ACTION_SEND);
            intent.setType("text/plain");
            intent.putExtra(Intent.EXTRA_SUBJECT, subject == null ? "Smart ATS Pro" : subject);
            intent.putExtra(Intent.EXTRA_TEXT, text == null ? "" : text);
            context.startActivity(Intent.createChooser(intent, "共有"));
        }

        @JavascriptInterface
        public void composeEmail(String to, String subject, String body) {
            Uri uri = Uri.parse("mailto:" + Uri.encode(to == null ? "" : to));
            Intent intent = new Intent(Intent.ACTION_SENDTO, uri);
            intent.putExtra(Intent.EXTRA_SUBJECT, subject == null ? "" : subject);
            intent.putExtra(Intent.EXTRA_TEXT, body == null ? "" : body);
            try {
                context.startActivity(Intent.createChooser(intent, "メールアプリを選択"));
            } catch (Exception ignored) { }
        }

        @JavascriptInterface
        public boolean isGmailInstalled() {
            try {
                context.getPackageManager().getPackageInfo("com.google.android.gm", PackageManager.GET_ACTIVITIES);
                return true;
            } catch (Exception e) {
                return false;
            }
        }

        @JavascriptInterface
        public boolean hasGeminiApiKey() {
            return !loadEncryptedApiKey().isEmpty();
        }

        @JavascriptInterface
        public String getGeminiApiKeyMask() {
            String key = loadEncryptedApiKey();
            if (key.length() < 8) return key.isEmpty() ? "" : "設定済み";
            return key.substring(0, 4) + "••••••••" + key.substring(key.length() - 4);
        }

        @JavascriptInterface
        public void saveGeminiApiKey(String apiKey) {
            String key = apiKey == null ? "" : apiKey.trim();
            if (key.length() < 20 || key.length() > 200) throw new IllegalArgumentException("Invalid API key");
            try {
                saveEncryptedApiKey(key);
            } catch (Exception e) {
                throw new IllegalStateException("Could not protect API key");
            }
        }

        @JavascriptInterface
        public void clearGeminiApiKey() {
            prefs().edit().remove(PREF_API_KEY).apply();
        }

        @JavascriptInterface
        public String getGeminiModel() {
            String value = prefs().getString(PREF_MODEL, DEFAULT_MODEL);
            return value == null || !SAFE_MODEL.matcher(value).matches() ? DEFAULT_MODEL : value;
        }

        @JavascriptInterface
        public void saveGeminiModel(String model) {
            String value = model == null ? "" : model.trim();
            if (!SAFE_MODEL.matcher(value).matches()) throw new IllegalArgumentException("Invalid model name");
            prefs().edit().putString(PREF_MODEL, value).apply();
        }

        @JavascriptInterface
        public String saveEncryptedDocument(String candidateId, String fileName, String mimeType, String base64Data) {
            try {
                String cid = candidateId == null ? "" : candidateId.trim();
                if (!SAFE_ID.matcher(cid).matches()) throw new IllegalArgumentException("Invalid candidate id");
                String mime = mimeType == null ? "" : mimeType.trim();
                if (!("application/pdf".equals(mime) || "image/png".equals(mime) || "image/jpeg".equals(mime))) {
                    throw new IllegalArgumentException("Unsupported file type");
                }
                if (base64Data == null || base64Data.length() > 15_000_000) throw new IllegalArgumentException("File too large");
                byte[] plain = Base64.decode(base64Data, Base64.DEFAULT);
                if (plain.length == 0 || plain.length > MAX_DOCUMENT_BYTES) throw new IllegalArgumentException("File too large");

                String docId = "doc_" + UUID.randomUUID().toString().replace("-", "");
                Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
                cipher.init(Cipher.ENCRYPT_MODE, getOrCreateKey(DOC_KEY_ALIAS));
                byte[] encrypted = cipher.doFinal(plain);
                File out = new File(documentDirectory(), docId + ".bin");
                try (DataOutputStream dos = new DataOutputStream(new FileOutputStream(out))) {
                    byte[] iv = cipher.getIV();
                    dos.writeInt(iv.length);
                    dos.write(iv);
                    dos.writeInt(encrypted.length);
                    dos.write(encrypted);
                }

                JSONObject item = new JSONObject();
                item.put("id", docId);
                item.put("candidateId", cid);
                item.put("name", safeFileName(fileName));
                item.put("mimeType", mime);
                item.put("size", plain.length);
                item.put("createdAt", System.currentTimeMillis());
                JSONArray meta = loadDocumentMeta();
                meta.put(item);
                saveDocumentMeta(meta);
                return item.toString();
            } catch (Exception e) {
                return errorJson(e.getMessage());
            }
        }

        @JavascriptInterface
        public String listCandidateDocuments(String candidateId) {
            try {
                String cid = candidateId == null ? "" : candidateId.trim();
                JSONArray all = loadDocumentMeta();
                JSONArray result = new JSONArray();
                for (int i = 0; i < all.length(); i++) {
                    JSONObject item = all.optJSONObject(i);
                    if (item != null && cid.equals(item.optString("candidateId"))) {
                        result.put(new JSONObject(item.toString()));
                    }
                }
                return result.toString();
            } catch (Exception e) {
                return "[]";
            }
        }

        @JavascriptInterface
        public boolean deleteEncryptedDocument(String documentId) {
            try {
                String did = documentId == null ? "" : documentId.trim();
                if (!SAFE_ID.matcher(did).matches()) return false;
                JSONArray all = loadDocumentMeta();
                JSONArray next = new JSONArray();
                boolean found = false;
                for (int i = 0; i < all.length(); i++) {
                    JSONObject item = all.optJSONObject(i);
                    if (item == null) continue;
                    if (did.equals(item.optString("id"))) {
                        found = true;
                        File file = new File(documentDirectory(), did + ".bin");
                        if (file.exists()) file.delete();
                    } else {
                        next.put(item);
                    }
                }
                if (found) saveDocumentMeta(next);
                return found;
            } catch (Exception e) {
                return false;
            }
        }

        @JavascriptInterface
        public void testSupabaseConnection(String projectUrl, String anonKey, String callbackId) {
            final String urlText = projectUrl == null ? "" : projectUrl.trim().replaceAll("/+$", "");
            final String key = anonKey == null ? "" : anonKey.trim();
            if (!SUPABASE_URL.matcher(urlText + "/").matches() || key.length() < 20 || key.length() > 1000) {
                callbackIntegration(callbackId, false, "Supabase URLまたは公開キーを確認してください");
                return;
            }
            networkExecutor.execute(() -> {
                HttpsURLConnection connection = null;
                try {
                    URL url = new URL(urlText + "/rest/v1/");
                    connection = (HttpsURLConnection) url.openConnection();
                    connection.setRequestMethod("GET");
                    connection.setConnectTimeout(15_000);
                    connection.setReadTimeout(20_000);
                    connection.setRequestProperty("apikey", key);
                    connection.setRequestProperty("Authorization", "Bearer " + key);
                    connection.setRequestProperty("Accept", "application/json");
                    int code = connection.getResponseCode();
                    if (code >= 200 && code < 300) {
                        callbackIntegration(callbackId, true, "Supabase REST APIへ接続できました。候補者データは送信していません。");
                    } else if (code == 401 || code == 403) {
                        callbackIntegration(callbackId, false, "接続先には到達しましたが、公開キーが拒否されました (" + code + ")");
                    } else {
                        callbackIntegration(callbackId, false, "接続先からHTTP " + code + " が返りました");
                    }
                } catch (Exception e) {
                    callbackIntegration(callbackId, false, "Supabase接続に失敗しました: " + e.getClass().getSimpleName());
                } finally {
                    if (connection != null) connection.disconnect();
                }
            });
        }

        @JavascriptInterface
        public void geminiGenerate(String requestJson, String callbackId) {
            final String apiKey = loadEncryptedApiKey();
            final String model = getGeminiModel();
            if (apiKey.isEmpty()) {
                callbackGemini(callbackId, false, "Gemini APIキーが設定されていません");
                return;
            }
            if (requestJson == null || requestJson.length() > 18_000_000) {
                callbackGemini(callbackId, false, "送信データが大きすぎます");
                return;
            }
            networkExecutor.execute(() -> {
                HttpsURLConnection connection = null;
                try {
                    URL url = new URL("https://generativelanguage.googleapis.com/v1beta/models/" + model + ":generateContent");
                    connection = (HttpsURLConnection) url.openConnection();
                    connection.setRequestMethod("POST");
                    connection.setConnectTimeout(20_000);
                    connection.setReadTimeout(90_000);
                    connection.setDoOutput(true);
                    connection.setRequestProperty("Content-Type", "application/json; charset=utf-8");
                    connection.setRequestProperty("x-goog-api-key", apiKey);
                    connection.setRequestProperty("Accept", "application/json");
                    byte[] bytes = requestJson.getBytes(StandardCharsets.UTF_8);
                    connection.setFixedLengthStreamingMode(bytes.length);
                    try (OutputStream os = connection.getOutputStream()) { os.write(bytes); }
                    int code = connection.getResponseCode();
                    String responseBody = readStream(code >= 200 && code < 300 ? connection.getInputStream() : connection.getErrorStream());
                    if (code >= 200 && code < 300) callbackGemini(callbackId, true, responseBody);
                    else callbackGemini(callbackId, false, "Gemini API error (" + code + "): " + responseBody);
                } catch (Exception e) {
                    callbackGemini(callbackId, false, "Gemini通信に失敗しました: " + e.getClass().getSimpleName());
                } finally {
                    if (connection != null) connection.disconnect();
                }
            });
        }
    }
}
