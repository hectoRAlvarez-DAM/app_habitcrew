plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.app_habitcrew"
    compileSdk = 36

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    
    }

    defaultConfig {
        applicationId = "com.example.app_habitcrew"
        
        // Mantenemos un valor fijo para evitar conflictos de inicialización
        minSdk = flutter.minSdkVersion 
        targetSdk = 36
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
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
    implementation("androidx.lifecycle:lifecycle-common-java8:2.8.7")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
