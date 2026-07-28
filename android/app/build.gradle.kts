plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ntgptit.memox"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.ntgptit.memox"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Required for the per-flavor `resValue("string", "app_name", ...)` below:
    // recent AGP defaults this off, and a flavor that declares a resource value
    // without it fails the build outright rather than ignoring the value.
    buildFeatures {
        resValues = true
    }

    // Three flavors so all three builds install side by side on one device.
    // Distinct applicationIds are the whole point: without the suffix,
    // installing staging replaces production, and a tester loses their data
    // without being told why.
    //
    // `app_name` is a resource rather than a literal in the manifest, so the
    // launcher label is chosen per flavor in exactly one place.
    flavorDimensions += "environment"

    productFlavors {
        create("development") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "MemoX Dev")
        }
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".staging"
            resValue("string", "app_name", "MemoX Staging")
        }
        create("production") {
            dimension = "environment"
            // No suffix: production owns the base applicationId.
            resValue("string", "app_name", "MemoX")
        }
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
