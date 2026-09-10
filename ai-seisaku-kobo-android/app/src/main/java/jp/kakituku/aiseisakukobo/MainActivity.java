package jp.kakituku.aiseisakukobo;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.speech.RecognitionListener;
import android.speech.RecognizerIntent;
import android.speech.SpeechRecognizer;
import android.webkit.JavascriptInterface;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import org.json.JSONObject;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.Locale;
import java.util.Set;

public class MainActivity extends Activity {
    private static final int AUDIO_PERMISSION = 7001;
    private WebView webView;
    private SpeechRecognizer recognizer;
    private Intent recognizerIntent;
    private final Handler handler = new Handler(Looper.getMainLooper());
    private final ArrayList<String> segments = new ArrayList<>();
    private final Set<String> normalizedSeen = new LinkedHashSet<>();
    private boolean keepListening = false;
    private boolean stopRequested = false;
    private boolean finalized = false;
    private String pendingTargetId = "";

    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        webView = new WebView(this);
        setContentView(webView);
        WebSettings s = webView.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setDatabaseEnabled(true);
        s.setAllowFileAccess(true);
        s.setAllowContentAccess(true);
        webView.setWebViewClient(new WebViewClient());
        webView.setWebChromeClient(new WebChromeClient());
        webView.addJavascriptInterface(new NativeVoiceBridge(), "NativeVoice");
        webView.loadUrl("file:///android_asset/index.html");
    }

    public class NativeVoiceBridge {
        @JavascriptInterface public void start(String targetId) {
            runOnUiThread(() -> startNativeVoice(targetId == null ? "" : targetId));
        }
        @JavascriptInterface public void stop() {
            runOnUiThread(MainActivity.this::stopNativeVoice);
        }
        @JavascriptInterface public boolean isAvailable() {
            return SpeechRecognizer.isRecognitionAvailable(MainActivity.this);
        }
    }

    private void startNativeVoice(String targetId) {
        pendingTargetId = targetId;
        if (checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(new String[]{Manifest.permission.RECORD_AUDIO}, AUDIO_PERMISSION);
            return;
        }
        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            js("onError", "この端末でAndroid音声認識サービスを利用できません。Google音声サービスの有効化を確認してください。");
            return;
        }
        destroyRecognizer();
        segments.clear();
        normalizedSeen.clear();
        finalized = false;
        keepListening = true;
        stopRequested = false;
        recognizer = SpeechRecognizer.createSpeechRecognizer(this);
        recognizerIntent = new Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH);
        recognizerIntent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM);
        recognizerIntent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, "ja-JP");
        recognizerIntent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, "ja-JP");
        recognizerIntent.putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true);
        recognizerIntent.putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1);
        recognizer.setRecognitionListener(new RecognitionListener() {
            @Override public void onReadyForSpeech(Bundle params) { js("onReady", ""); }
            @Override public void onBeginningOfSpeech() { }
            @Override public void onRmsChanged(float rmsdB) { }
            @Override public void onBufferReceived(byte[] buffer) { }
            @Override public void onEndOfSpeech() { }
            @Override public void onError(int error) {
                if (stopRequested) { finalizeNativeVoice(); return; }
                if (error == SpeechRecognizer.ERROR_NO_MATCH || error == SpeechRecognizer.ERROR_SPEECH_TIMEOUT || error == SpeechRecognizer.ERROR_CLIENT) {
                    scheduleRestart();
                } else if (error == SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS) {
                    keepListening = false;
                    js("onError", "マイク権限を許可してください。");
                } else if (keepListening) {
                    scheduleRestart();
                } else {
                    js("onError", "音声認識でエラーが発生しました。もう一度お試しください。");
                }
            }
            @Override public void onResults(Bundle results) {
                ArrayList<String> list = results.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION);
                if (list != null && !list.isEmpty()) addSegment(list.get(0));
                if (stopRequested) finalizeNativeVoice(); else scheduleRestart();
            }
            @Override public void onPartialResults(Bundle partialResults) {
                ArrayList<String> list = partialResults.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION);
                if (list != null && !list.isEmpty()) js("onPartial", list.get(0));
            }
            @Override public void onEvent(int eventType, Bundle params) { }
        });
        startListeningNow();
    }

    private void startListeningNow() {
        if (!keepListening || recognizer == null || recognizerIntent == null) return;
        try { recognizer.startListening(recognizerIntent); }
        catch (Exception e) { handler.postDelayed(this::startListeningNow, 450); }
    }

    private void scheduleRestart() {
        if (!keepListening || stopRequested) return;
        handler.postDelayed(this::startListeningNow, 350);
    }

    private String normalize(String value) {
        if (value == null) return "";
        return value.toLowerCase(Locale.JAPAN).replaceAll("[\\s、。,.!?！？]", "");
    }

    private void addSegment(String text) {
        if (text == null) return;
        String clean = text.trim();
        String n = normalize(clean);
        if (n.isEmpty() || normalizedSeen.contains(n)) return;
        normalizedSeen.add(n);
        segments.add(clean);
        js("onCommitted", String.join(" ", segments));
    }

    private void stopNativeVoice() {
        stopRequested = true;
        keepListening = false;
        if (recognizer != null) {
            try { recognizer.stopListening(); } catch (Exception ignored) { }
        }
        handler.postDelayed(this::finalizeNativeVoice, 750);
    }

    private void finalizeNativeVoice() {
        if (finalized) return;
        finalized = true;
        keepListening = false;
        stopRequested = true;
        String text = String.join(" ", segments).trim();
        destroyRecognizer();
        js("onFinalText", text);
    }

    private void js(String method, String value) {
        String arg = JSONObject.quote(value == null ? "" : value);
        handler.post(() -> webView.evaluateJavascript("window.AISeisakuNativeVoice&&window.AISeisakuNativeVoice." + method + "(" + arg + ");", null));
    }

    private void destroyRecognizer() {
        if (recognizer != null) {
            try { recognizer.cancel(); recognizer.destroy(); } catch (Exception ignored) { }
        }
        recognizer = null;
    }

    @Override public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == AUDIO_PERMISSION) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) startNativeVoice(pendingTargetId);
            else js("onError", "マイク権限が許可されていません。Android設定からAI制作工房のマイクを許可してください。");
        }
    }

    @Override public void onBackPressed() {
        if (webView != null && webView.canGoBack()) webView.goBack(); else super.onBackPressed();
    }

    @Override protected void onDestroy() {
        destroyRecognizer();
        if (webView != null) webView.destroy();
        super.onDestroy();
    }
}
