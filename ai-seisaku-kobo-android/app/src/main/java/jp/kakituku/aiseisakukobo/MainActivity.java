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

public class MainActivity extends Activity {
    private static final int AUDIO_PERMISSION = 7001;
    private WebView webView;
    private SpeechRecognizer recognizer;
    private Intent recognizerIntent;
    private final Handler handler = new Handler(Looper.getMainLooper());
    private String finalText = "";
    private String latestPartial = "";
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
        finalText = "";
        latestPartial = "";
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
                if (stopRequested || error == SpeechRecognizer.ERROR_NO_MATCH || error == SpeechRecognizer.ERROR_SPEECH_TIMEOUT || error == SpeechRecognizer.ERROR_CLIENT) {
                    finalizeNativeVoice();
                } else if (error == SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS) {
                    keepListening = false;
                    js("onError", "マイク権限を許可してください。");
                } else {
                    keepListening = false;
                    js("onError", "音声認識でエラーが発生しました。もう一度お試しください。");
                }
            }
            @Override public void onResults(Bundle results) {
                ArrayList<String> list = results.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION);
                if (list != null && !list.isEmpty()) finalText = list.get(0).trim();
                keepListening = false;
                stopRequested = true;
                finalizeNativeVoice();
            }
            @Override public void onPartialResults(Bundle partialResults) {
                ArrayList<String> list = partialResults.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION);
                if (list != null && !list.isEmpty()) {
                    latestPartial = list.get(0).trim();
                    js("onPartial", latestPartial);
                }
            }
            @Override public void onEvent(int eventType, Bundle params) { }
        });
        startListeningNow();
    }

    private void startListeningNow() {
        if (!keepListening || recognizer == null || recognizerIntent == null) return;
        try { recognizer.startListening(recognizerIntent); }
        catch (Exception e) {
            keepListening = false;
            js("onError", "音声認識を開始できませんでした。もう一度お試しください。");
        }
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
        String text = finalText.isEmpty() ? latestPartial : finalText;
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
