import java.util.Properties
import java.io.File

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.app_habitcrew"
    compileSdk = 35

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    
    }

    defaultConfig {
        applicationId = "com.example.app_habitcrew"
        
        // Mantenemos un valor fijo para evitar conflictos de inicialización
        minSdk = flutter.minSdkVersion 
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
    }

    // SOLUCIÓN AL ERROR 2: Evita la duplicidad de libflutter.so
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
        jniLibs {
            useLegacyPackaging = true
            pickFirsts += "**/libflutter.so"
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            
            signingConfig = signingConfigs.getByName("debug")
            
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }
    configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "io.flutter") {
                useVersion(requested.version)
            }
        }
    }
}

dependencies {
    // 1. Cargamos el archivo local.properties de forma segura
    val localProperties = Properties()
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        localPropertiesFile.inputStream().use { localProperties.load(it) }
    }
    val flutterSdkPath = localProperties.getProperty("flutter.sdk")

    // 2. Si la ruta existe, inyectamos los JARs necesarios
    if (flutterSdkPath != null) {
        implementation(fileTree(mapOf("dir" to "$flutterSdkPath/bin/cache/artifacts/engine/android-arm64", "include" to listOf("*.jar"))))
        implementation(fileTree(mapOf("dir" to "$flutterSdkPath/bin/cache/artifacts/engine/android-x64", "include" to listOf("*.jar"))))
    }

    // 3. Librerías de soporte vital para AndroidX y Lifecycle
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
    implementation("androidx.lifecycle:lifecycle-common-java8:2.8.7")
    
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
