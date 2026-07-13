package com.example.civic_voice

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "civic_voice/config",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "googleMapsApiKey" -> result.success(BuildConfig.GOOGLE_MAPS_API_KEY)
                else -> result.notImplemented()
            }
        }
    }
}
