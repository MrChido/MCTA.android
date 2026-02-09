import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("android/key.properties")

println("DEBUG - rootProject dir: ${rootProject.projectDir}")
println("DEBUG - File exists: ${keystorePropertiesFile.exists()}")
if (keystorePropertiesFile.exists()){
    keystoreProperties.load(keystorePropertiesFile.inputStream())
    println("DEBUG - Loaded keys: ${keystoreProperties.keys}")
}

android {
    namespace = "com.soggywombat.spoonie"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.soggywombat.spoonie"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 2
        versionName = "Vision 1Ab"
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            signingConfig = signingConfigs.getByName("release")
        }
    }

    dependencies {
        implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.8.22")
        coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    }
}


flutter {
    source = "../.."
}
