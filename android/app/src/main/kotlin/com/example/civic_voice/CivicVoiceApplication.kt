package com.example.civic_voice

import android.app.Application
import android.content.Context
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterJNI

class CivicVoiceApplication : Application() {
    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)
        // Install before providers/plugins can access FlutterInjector. Keep its
        // default loader/executor and the Activity's ordinary engine lifecycle.
        FlutterInjector.setInstance(
            FlutterInjector.Builder()
                .setFlutterJNIFactory(object : FlutterJNI.Factory() {
                    override fun provideFlutterJNI(): FlutterJNI = PasswordMaskingFlutterJNI()
                })
                .build(),
        )
    }
}
