package com.example.civic_voice

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.MethodChannel
import android.content.pm.PackageManager
import android.os.Build
import java.security.MessageDigest

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "civic_voice/config",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "googleMapsApiKey" -> result.success(BuildConfig.GOOGLE_MAPS_API_KEY)
                "googleMapsRequestConfig" -> {
                    try {
                        @Suppress("DEPRECATION")
                        val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
                                .signingInfo?.apkContentsSigners
                        } else {
                            packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES).signatures
                        }
                        val certificate = signatures?.singleOrNull()
                            ?: throw IllegalStateException("Application signing identity unavailable")
                        val digest = MessageDigest.getInstance("SHA-1").digest(certificate.toByteArray())
                            .joinToString("") { "%02X".format(it.toInt() and 0xff) }
                        result.success(mapOf(
                            "apiKey" to BuildConfig.GOOGLE_MAPS_API_KEY,
                            "androidPackage" to packageName,
                            "androidCert" to digest,
                        ))
                    } catch (_: Exception) {
                        result.error("MAPS_CONFIG_UNAVAILABLE", "Maps application identity unavailable", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
