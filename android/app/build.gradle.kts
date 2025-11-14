// Archivo: android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.mi_rutina_visual"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.mi_rutina_visual"
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"

        // Habilitar soporte multidex y desugaring (para librerías Java 8+)
        multiDexEnabled = true
    }

    compileOptions {
        // Soporte para API modernas
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    // 🔧 Ajuste definitivo para evitar errores de shrinkResources / minifyEnabled
    buildTypes {
        getByName("release") {
            // 🔐 Firma temporal (usando las llaves de debug)
            signingConfig = signingConfigs.getByName("debug")

            // ❌ Desactivar completamente reducción de código o recursos
            isMinifyEnabled = false
            // shrinkResources también desactivado explícitamente
            isShrinkResources = false
        }

        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }


    ndkVersion = "27.0.12077973"
}

dependencies {
    // Kotlin estándar
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.8.22")

    // Core AndroidX
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.multidex:multidex:2.0.1")

    // Desugaring para APIs Java 8+
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // Firebase (si lo usas)
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))
    implementation("com.google.firebase:firebase-analytics")

    // Notificaciones locales
    implementation("androidx.work:work-runtime-ktx:2.9.1")
}

flutter {
    source = "../.."
}
