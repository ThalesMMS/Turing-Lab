import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

fun envOrNull(name: String): String? = System.getenv(name)?.takeIf { it.isNotBlank() }

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
} else {
    val envStorePassword = envOrNull("TURING_LAB_KEYSTORE_PASSWORD")
    val envKeyAlias = envOrNull("TURING_LAB_KEY_ALIAS")
    val envKeyPassword = envOrNull("TURING_LAB_KEY_PASSWORD")
    if (envStorePassword != null && envKeyAlias != null && envKeyPassword != null) {
        val envStoreFile = envOrNull("TURING_LAB_KEYSTORE_PATH") ?: "keystores/turing-lab-release.jks"
        keystoreProperties.setProperty("storeFile", envStoreFile)
        keystoreProperties.setProperty("storePassword", envStorePassword)
        keystoreProperties.setProperty("keyAlias", envKeyAlias)
        keystoreProperties.setProperty("keyPassword", envKeyPassword)
        println("Loaded release keystore credentials from environment variables.")
    } else {
        val providedEnv = listOfNotNull(
            envStorePassword?.let { "TURING_LAB_KEYSTORE_PASSWORD" },
            envKeyAlias?.let { "TURING_LAB_KEY_ALIAS" },
            envKeyPassword?.let { "TURING_LAB_KEY_PASSWORD" }
        )
        if (providedEnv.isNotEmpty()) {
            println("Warning: Incomplete keystore environment configuration. Provided: ${'$'}{providedEnv.joinToString()}.")
        } else {
            println("Warning: key.properties not found and no keystore environment variables are set. Release builds will require a signing configuration.")
        }
    }
}

android {
    namespace = "thalesmms.turinglab"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "thalesmms.turinglab"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storeFilePath = keystoreProperties["storeFile"] as String?
            if (!storeFilePath.isNullOrBlank()) {
                storeFile = rootProject.file(storeFilePath)
            }
            storePassword = keystoreProperties["storePassword"] as String?
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystoreProperties.isNotEmpty()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
