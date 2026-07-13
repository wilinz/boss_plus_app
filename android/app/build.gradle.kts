import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.reader(Charsets.UTF_8).use { reader ->
        localProperties.load(reader)
    }
}

// 签名参数:优先 local.properties(本地),回退到环境变量(CI 用 —— Flutter 构建会
// 重写 local.properties,故 CI 通过 env 注入更可靠)。
fun signingProp(localKey: String, envKey: String): String? =
    (localProperties[localKey] as String?) ?: System.getenv(envKey)

val relStoreFile = signingProp("storeFile", "ANDROID_STORE_FILE")
val relStorePassword = signingProp("storePassword", "ANDROID_STORE_PASSWORD")
val relKeyAlias = signingProp("keyAlias", "ANDROID_KEY_ALIAS")
val relKeyPassword = signingProp("keyPassword", "ANDROID_KEY_PASSWORD")

android {
    namespace = "com.wilinz.boss_plus_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.wilinz.boss_plus_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (relStoreFile != null) {
                storeFile = file(relStoreFile)
                storePassword = relStorePassword
                keyAlias = relKeyAlias
                keyPassword = relKeyPassword
            } else {
                println("Release build signing not configured. Use debug signing.")
            }
        }
    }

    buildTypes {
        release {
            ndk {
                abiFilters.clear()
                abiFilters.add("arm64-v8a")
            }
            signingConfig = if (relStoreFile != null) {
                signingConfigs.getByName("release")
            } else {
                // Signing with the debug keys for now, so `flutter run --release` works.
                signingConfigs.getByName("debug")
            }
            proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}

flutter {
    source = "../.."
}
