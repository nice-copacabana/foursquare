plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseSigningValues =
    mapOf(
        "ANDROID_KEYSTORE_PATH" to System.getenv("ANDROID_KEYSTORE_PATH"),
        "ANDROID_KEYSTORE_PASSWORD" to System.getenv("ANDROID_KEYSTORE_PASSWORD"),
        "ANDROID_KEY_ALIAS" to System.getenv("ANDROID_KEY_ALIAS"),
        "ANDROID_KEY_PASSWORD" to System.getenv("ANDROID_KEY_PASSWORD"),
    )
val releaseSigningConfigured =
    releaseSigningValues.values.all { !it.isNullOrBlank() }
val developmentApplicationId = "com.qoder.foursquare"

android {
    namespace = "com.qoder.foursquare"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Development-only identifier. Replacing it with the permanent package
        // name is a hard gate before the first store release.
        applicationId = developmentApplicationId
        minSdk = 26
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseSigningConfigured) {
            create("release") {
                storeFile = rootProject.file(releaseSigningValues.getValue("ANDROID_KEYSTORE_PATH")!!)
                storePassword = releaseSigningValues.getValue("ANDROID_KEYSTORE_PASSWORD")
                keyAlias = releaseSigningValues.getValue("ANDROID_KEY_ALIAS")
                keyPassword = releaseSigningValues.getValue("ANDROID_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            if (releaseSigningConfigured) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

val verifyReleaseSigning by
    tasks.registering {
        group = "verification"
        description = "Fails release builds unless all production signing inputs are present."

        doLast {
            if (android.defaultConfig.applicationId == developmentApplicationId) {
                throw GradleException(
                    "Release applicationId is still the development placeholder: " +
                        developmentApplicationId,
                )
            }

            val missingVariables =
                releaseSigningValues
                    .filterValues { it.isNullOrBlank() }
                    .keys
                    .sorted()

            if (missingVariables.isNotEmpty()) {
                throw GradleException(
                    "Release signing is not configured. Missing environment variables: " +
                        missingVariables.joinToString(", "),
                )
            }

            val keystoreFile =
                rootProject.file(releaseSigningValues.getValue("ANDROID_KEYSTORE_PATH")!!)
            if (!keystoreFile.isFile) {
                throw GradleException(
                    "Release keystore does not exist at the configured ANDROID_KEYSTORE_PATH.",
                )
            }
        }
    }

tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    dependsOn(verifyReleaseSigning)
}

flutter {
    source = "../.."
}
