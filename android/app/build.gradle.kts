// android/app/build.gradle.kts
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

// IMPORTANT: Diagnostic line to print the absolute path Gradle is looking for
println("DEBUG: Looking for key.properties at: ${keystorePropertiesFile.absolutePath}")

// IMPORTANT: Add a more explicit check and error message here
if (!keystorePropertiesFile.exists()) {
    throw GradleException("key.properties file not found at ${keystorePropertiesFile.absolutePath}. Please create it with your keystore details.")
}

keystoreProperties.load(FileInputStream(keystorePropertiesFile))

// IMPORTANT: Add a check for the storeFile property itself
if (keystoreProperties.getProperty("storeFile").isNullOrEmpty()) {
    throw GradleException("The 'storeFile' property is missing or empty in key.properties. Please ensure it's correctly defined.")
}


android {
    namespace = "com.example.fouta_app"
    compileSdk = flutter.compileSdkVersion.toInt()
    ndkVersion = "27.0.12077973"
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // IMPORTANT: Change this to a unique package name for your app.
        // Example: "com.yourcompany.foutaapp" or "com.fouta.appname"
        applicationId = "com.fouta.foutaapp" // Changed from "com.example.fouta_app"
        minSdk = flutter.minSdkVersion.toInt()
        targetSdk = flutter.targetSdkVersion.toInt()
        versionCode = flutter.versionCode.toInt()
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = file(keystoreProperties.getProperty("storeFile"))
            storePassword = keystoreProperties.getProperty("storePassword")
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isShrinkResources = true
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
