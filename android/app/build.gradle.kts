plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // Agrega esta línea aquí
}

android {
    namespace = "com.pizzabrosa.app"  // Cambia esto por tu namespace real
    compileSdk = 34

    defaultConfig {
        applicationId = "com.pizzabrosa.app"  // Debe coincidir con el namespace
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }
}

dependencies {
    implementation(platform("org.jetbrains.kotlin:kotlin-bom"))
    // Agrega otras dependencias aquí si las necesitas
}

// Esta línea es fundamental para que Firebase funcione

