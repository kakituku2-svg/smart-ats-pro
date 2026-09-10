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
  private WebView web;

  @Override public void onCreate(Bundle b) {
    super.onCreate(b);
    web = new WebView(this);
    setContentView(web);
    configure();
    loadBundledApp();
  }

  private void configure() {
    WebSettings s = web.getSettings();
    s.setJavaScriptEnabled(true);
    s.setDomStorageEnabled(true);
    s.setAllowFileAccess(true);
    s.setAllowContentAccess(true);
    s.setMediaPlaybackRequiresUserGesture(true);
    web.setWebViewClient(new WebViewClient() {
      @Override public boolean shouldOverrideUrlLoading(WebView v, WebResourceRequest r) {
        Uri u = r.getUrl();
        if ("file".equals(u.getScheme()) || "data".equals(u.getScheme())) return false;
        try { startActivity(new Intent(Intent.ACTION_VIEW, u)); } catch (Exception ignored) {}
        return true;
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
      String html = new String(htmlOut.toByteArray(), StandardCharsets.UTF_8);
      web.loadDataWithBaseURL("file:///android_asset/", html, "text/html", "UTF-8", null);
    } catch (Exception e) {
      String msg = "<html><body style='background:#090d14;color:#fff;font-family:sans-serif;padding:24px'><h2>設定看破AI</h2><p>アプリ本体の読み込みに失敗しました。</p></body></html>";
      web.loadData(msg, "text/html", "UTF-8");
    }
  }

  @Override public void onBackPressed() {
    if (web.canGoBack()) web.goBack(); else super.onBackPressed();
  }
}
