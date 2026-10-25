#!/bin/bash
set -e
D=android/app/src/main/java/com/heavenbd/app
mkdir -p "$D"
cat > "$D/MainActivity.java" <<'JAVA'
package com.heavenbd.app;

import android.os.Bundle;
import android.view.View;
import android.graphics.Color;
import android.webkit.WebSettings;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().getDecorView().setBackgroundColor(Color.WHITE);
    }

    @Override
    public void onStart() {
        super.onStart();
        getBridge().getWebView().setOverScrollMode(View.OVER_SCROLL_NEVER);
        getBridge().getWebView().setBackgroundColor(Color.WHITE);
        getBridge().getWebView().getSettings().setForceDark(WebSettings.FORCE_DARK_OFF);
        getWindow().setStatusBarColor(Color.WHITE);
    }
}
JAVA
M=android/app/src/main/AndroidManifest.xml
# open heaven-bd.vercel.app links inside the app
sed -i '0,/<\/activity>/s#</activity>#        <intent-filter android:autoVerify="true"><action android:name="android.intent.action.VIEW" /><category android:name="android.intent.category.DEFAULT" /><category android:name="android.intent.category.BROWSABLE" /><data android:scheme="https" android:host="heaven-bd.vercel.app" /></intent-filter>\n        </activity>#' "$M"
# camera for photo upload
sed -i 's#<application#<uses-permission android:name="android.permission.CAMERA" />\n    <application#' "$M"
# each build gets a higher version number, so the app can tell when a newer one exists
N="${GITHUB_RUN_NUMBER:-1}"
sed -i "s/versionCode [0-9]*/versionCode $N/; s/versionName \"[^\"]*\"/versionName \"1.$N\"/" android/app/build.gradle
grep -n "versionCode\|versionName" android/app/build.gradle || true
# sign the debug build with our permanent key (explicit path, not ~/.android)
sed -i '0,/^android {/s#^android {#android {\n    signingConfigs {\n        debug {\n            storeFile file("heaven.keystore")\n            storePassword "android"\n            keyAlias "androiddebugkey"\n            keyPassword "android"\n        }\n    }#' android/app/build.gradle
