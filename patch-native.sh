#!/bin/bash
set -e
D=android/app/src/main/java/com/heavenbd/app
mkdir -p "$D"
cat > "$D/MainActivity.java" <<'JAVA'
package com.heavenbd.app;

import android.os.Bundle;
import android.view.View;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    public void onStart() {
        super.onStart();
        getBridge().getWebView().setOverScrollMode(View.OVER_SCROLL_NEVER);
    }
}
JAVA
