plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.pawfolio"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // 1. ENABLE DESUGARING HERE
        isCoreLibraryDesugaringEnabled = true
        
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.pawfolio"
        minSdk = flutter.minSdkVersion // Desugaring works best with minSdk 21+
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// 2. ADD THE DEPENDENCIES BLOCK AT THE BOTTOM
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}

flutter {
    source = "../.."
}
