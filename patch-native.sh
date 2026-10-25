#!/bin/bash
set -e
D=android/app/src/main/java/com/heavenbd/app
mkdir -p "$D"
cat > "$D/MainActivity.java" <<'JAVA'
package com.heavenbd.app;

import android.content.Intent;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.view.View;
import android.webkit.JavascriptInterface;
import android.webkit.WebSettings;
import androidx.core.content.FileProvider;
import com.getcapacitor.BridgeActivity;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;

public class MainActivity extends BridgeActivity {
    private volatile boolean downloading = false;
    private String pendingUrl = null;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().getDecorView().setBackgroundColor(Color.WHITE);
        getBridge().getWebView().addJavascriptInterface(new Updater(), "HeavenUpdater");
    }

    @Override
    public void onStart() {
        super.onStart();
        getBridge().getWebView().setOverScrollMode(View.OVER_SCROLL_NEVER);
        getBridge().getWebView().setBackgroundColor(Color.WHITE);
        getBridge().getWebView().getSettings().setForceDark(WebSettings.FORCE_DARK_OFF);
        getWindow().setStatusBarColor(Color.WHITE);
    }

    @Override
    public void onResume() {
        super.onResume();
        if (pendingUrl != null && canInstall()) {
            String u = pendingUrl;
            pendingUrl = null;
            new Updater().start(u);
        }
    }

    private boolean canInstall() {
        return Build.VERSION.SDK_INT < 26 || getPackageManager().canRequestPackageInstalls();
    }

    private void js(final int p, final String s) {
        runOnUiThread(new Runnable() {
            public void run() {
                try {
                    getBridge().getWebView().evaluateJavascript("window.__heavenUpdate&&window.__heavenUpdate(" + p + ",'" + s + "')", null);
                } catch (Exception e) {}
            }
        });
    }

    public class Updater {
        @JavascriptInterface
        public void start(final String url) {
            runOnUiThread(new Runnable() {
                public void run() {
                    if (!canInstall()) {
                        pendingUrl = url;
                        js(0, "perm");
                        try {
                            startActivity(new Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:" + getPackageName())));
                        } catch (Exception e) {}
                        return;
                    }
                    if (downloading) return;
                    downloading = true;
                    new Thread(new Runnable() {
                        public void run() { download(url); }
                    }).start();
                }
            });
        }
    }

    private void download(String url) {
        try {
            HttpURLConnection c = (HttpURLConnection) new URL(url).openConnection();
            c.setConnectTimeout(20000);
            c.setReadTimeout(30000);
            c.connect();
            int total = c.getContentLength();
            File f = new File(getCacheDir(), "HEAVEN-update.apk");
            InputStream in = c.getInputStream();
            FileOutputStream out = new FileOutputStream(f);
            byte[] buf = new byte[16384];
            int n;
            long got = 0;
            int last = -1;
            while ((n = in.read(buf)) > 0) {
                out.write(buf, 0, n);
                got += n;
                if (total > 0) {
                    int p = (int) (got * 100 / total);
                    if (p != last) { last = p; js(p, "load"); }
                }
            }
            out.close();
            in.close();
            js(100, "done");
            Uri uri = FileProvider.getUriForFile(this, getPackageName() + ".fileprovider", f);
            Intent i = new Intent(Intent.ACTION_VIEW);
            i.setDataAndType(uri, "application/vnd.android.package-archive");
            i.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(i);
        } catch (Exception e) {
            js(0, "error");
        } finally {
            downloading = false;
        }
    }
}
JAVA
M=android/app/src/main/AndroidManifest.xml
sed -i '0,/<\/activity>/s#</activity>#        <intent-filter android:autoVerify="true"><action android:name="android.intent.action.VIEW" /><category android:name="android.intent.category.DEFAULT" /><category android:name="android.intent.category.BROWSABLE" /><data android:scheme="https" android:host="heaven-bd.vercel.app" /></intent-filter>\n        </activity>#' "$M"
sed -i 's#<application#<uses-permission android:name="android.permission.CAMERA" />\n    <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />\n    <application#' "$M"
N="${GITHUB_RUN_NUMBER:-1}"
sed -i "s/versionCode [0-9]*/versionCode $N/; s/versionName \"[^\"]*\"/versionName \"1.$N\"/" android/app/build.gradle
sed -i '0,/^android {/s#^android {#android {\n    signingConfigs {\n        debug {\n            storeFile file("heaven.keystore")\n            storePassword "android"\n            keyAlias "androiddebugkey"\n            keyPassword "android"\n        }\n    }#' android/app/build.gradle
grep -n "versionCode\|versionName\|signingConfigs" android/app/build.gradle || true
