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
  private static final String[] PARTS = {"app-v4.6.part1.txt","app-v4.6.part2.txt","app-v4.6.part3.txt","app-v4.6.part4.txt","app-v4.6.part5.txt","app-v4.6.part6.txt","app-v4.6.part7.txt","app-v4.6.part8.txt"};
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
    s.setUserAgentString(s.getUserAgentString() + " HallScope/4.6 Android");
    web.setWebViewClient(new WebViewClient() {
      @Override public boolean shouldOverrideUrlLoading(WebView v, WebResourceRequest r) {
        Uri u = r.getUrl();
        if ("file".equals(u.getScheme()) || "data".equals(u.getScheme())) return false;
        if ("https".equals(u.getScheme()) && "kakituku2-svg.github.io".equals(u.getHost())) return false;
        try { startActivity(new Intent(Intent.ACTION_VIEW, u)); } catch (Exception ignored) {}
        return true;
      }
      @Override public void onReceivedError(WebView view, WebResourceRequest request, WebResourceError error) {
        if (request.isForMainFrame() && !fallbackLoaded) { fallbackLoaded = true; loadBundledApp(); }
      }
      @Override public void onReceivedHttpError(WebView view, WebResourceRequest request, WebResourceResponse response) {
        if (request.isForMainFrame() && response.getStatusCode() >= 400 && !fallbackLoaded) { fallbackLoaded = true; loadBundledApp(); }
      }
    });
    web.setWebChromeClient(new WebChromeClient());
  }

  private String readAsset(String name) throws IOException {
    InputStream in=getAssets().open(name); ByteArrayOutputStream out=new ByteArrayOutputStream();
    byte[] buf=new byte[8192]; int n; while((n=in.read(buf))!=-1) out.write(buf,0,n); in.close();
    return new String(out.toByteArray(), StandardCharsets.UTF_8).trim();
  }

  private void loadBundledApp() {
    try {
      StringBuilder b64 = new StringBuilder(); for(String p:PARTS) b64.append(readAsset(p));
      byte[] gz = Base64.decode(b64.toString(), Base64.DEFAULT);
      GZIPInputStream gzip = new GZIPInputStream(new ByteArrayInputStream(gz));
      ByteArrayOutputStream htmlOut = new ByteArrayOutputStream(); byte[] buf = new byte[8192]; int n;
      while ((n = gzip.read(buf)) != -1) htmlOut.write(buf, 0, n); gzip.close();
      String html = new String(htmlOut.toByteArray(), StandardCharsets.UTF_8);
      web.loadDataWithBaseURL("file:///android_asset/", html, "text/html", "UTF-8", null);
    } catch (Exception e) {
      String msg = "<html><body style='background:#f4f8fc;color:#172331;font-family:sans-serif;padding:24px'><h2>HALL SCOPE</h2><p>オンライン版と内蔵版の読み込みに失敗しました。</p></body></html>";
      web.loadData(msg, "text/html", "UTF-8");
    }
  }

  @Override public void onBackPressed() { if (web.canGoBack()) web.goBack(); else super.onBackPressed(); }
}
