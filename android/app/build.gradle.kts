import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

fun googleMapsApiKeyFromDartDefines(): String? {
    val dartDefines = project.findProperty("dart-defines") as String? ?: return null
    for (encoded in dartDefines.split(",")) {
        val decoded = try {
            String(Base64.getDecoder().decode(encoded), Charsets.UTF_8)
        } catch (_: IllegalArgumentException) {
            null
        } ?: continue

        if (decoded.startsWith("GOOGLE_MAPS_API_KEY=")) {
            return decoded.substringAfter("=").takeIf { it.isNotBlank() }
        }
    }
    return null
}

fun googleMapsApiKeyFromLocalProperties(): String? {
    val propertiesFile = rootProject.file("local.properties")
    if (!propertiesFile.exists()) return null

    val properties = Properties()
    propertiesFile.inputStream().use { properties.load(it) }
    return properties.getProperty("GOOGLE_MAPS_API_KEY")
        ?: properties.getProperty("googleMapsApiKey")
}

android {
    namespace = "com.example.civic_voice"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.civic_voice"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] =
            (project.findProperty("GOOGLE_MAPS_API_KEY") as String?)
                ?: googleMapsApiKeyFromDartDefines()
                ?: googleMapsApiKeyFromLocalProperties()
                ?: System.getenv("GOOGLE_MAPS_API_KEY")
                ?: ""
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
