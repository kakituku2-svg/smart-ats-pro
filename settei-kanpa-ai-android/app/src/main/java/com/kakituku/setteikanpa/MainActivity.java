package com.kakituku.setteikanpa;

import android.app.Activity;
import android.os.Bundle;
import android.webkit.*;
import android.content.*;
import android.net.Uri;
import android.util.Base64;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.zip.GZIPInputStream;

public class MainActivity extends Activity {
  private static final String HALL_SCOPE_URL = "https://kakituku2-svg.github.io/smart-ats-pro/hall-scope/";
  private WebView web;
  private boolean fallbackLoaded = false;

  @Override public void onCreate(Bundle b) {
    super.onCreate(b);
    web = new WebView(this);
    setContentView(web);
    configure();
    web.loadUrl(HALL_SCOPE_URL);
  }

  private void configure() {
    WebSettings s = web.getSettings();
    s.setJavaScriptEnabled(true);
    s.setDomStorageEnabled(true);
    s.setAllowFileAccess(true);
    s.setAllowContentAccess(true);
    s.setMediaPlaybackRequiresUserGesture(true);
    s.setUserAgentString(s.getUserAgentString() + " HallScope/Android");
    web.setWebViewClient(new WebViewClient() {
      @Override public boolean shouldOverrideUrlLoading(WebView v, WebResourceRequest r) {
        Uri u = r.getUrl();
        if ("file".equals(u.getScheme()) || "data".equals(u.getScheme())) return false;
        if ("https".equals(u.getScheme()) && "kakituku2-svg.github.io".equals(u.getHost())) return false;
        try { startActivity(new Intent(Intent.ACTION_VIEW, u)); } catch (Exception ignored) {}
        return true;
      }
      @Override public void onReceivedError(WebView view, WebResourceRequest request, WebResourceError error) {
        if (request.isForMainFrame() && !fallbackLoaded) {
          fallbackLoaded = true;
          loadBundledApp();
        }
      }
    });
    web.setWebChromeClient(new WebChromeClient());
  }

  private void loadBundledApp() {
    try {
      InputStream in = getAssets().open("app.html.gz.b64");
      ByteArrayOutputStream raw = new ByteArrayOutputStream();
      byte[] buf = new byte[8192];
      int n;
      while ((n = in.read(buf)) != -1) raw.write(buf, 0, n);
      in.close();
      byte[] gz = Base64.decode(new String(raw.toByteArray(), StandardCharsets.UTF_8).trim(), Base64.DEFAULT);
      GZIPInputStream gzip = new GZIPInputStream(new ByteArrayInputStream(gz));
      ByteArrayOutputStream htmlOut = new ByteArrayOutputStream();
      while ((n = gzip.read(buf)) != -1) htmlOut.write(buf, 0, n);
      gzip.close();
      String html = new String(htmlOut.toByteArray(), StandardCharsets.UTF_8)
        .replace("設定看破AI", "HALL SCOPE")
        .replace("STORE INTELLIGENCE / 店選び・イベント癖・台番予測", "店・イベント・台を読む / HALL INTELLIGENCE")
        .replace("PACHISLOT_RESEARCH_PROMPT_CONTROLLER", "HALL_SCOPE_RESEARCH_CONTROLLER")
        .replace("ATSUDai-4.1", "HALLSCOPE-4.5")
        .replace("v4.1", "v4.5");
      web.loadDataWithBaseURL("file:///android_asset/", html, "text/html", "UTF-8", null);
    } catch (Exception e) {
      String msg = "<html><body style='background:#f4f8fc;color:#172331;font-family:sans-serif;padding:24px'><h2>HALL SCOPE</h2><p>アプリ本体の読み込みに失敗しました。</p></body></html>";
      web.loadData(msg, "text/html", "UTF-8");
    }
  }

  @Override public void onBackPressed() {
    if (web.canGoBack()) web.goBack(); else super.onBackPressed();
  }
}
