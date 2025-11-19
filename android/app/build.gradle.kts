plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
}

// Load environment variables from .env.local
fun loadEnvFile(): Map<String, String> {
    val envFile = file("${rootProject.projectDir}/.env.local")
    val envVars = mutableMapOf<String, String>()
    
    if (envFile.exists()) {
        envFile.readLines().forEach { line ->
            val trimmed = line.trim()
            if (trimmed.isNotEmpty() && !trimmed.startsWith("#")) {
                val parts = trimmed.split("=", limit = 2)
                if (parts.size == 2) {
                    envVars[parts[0].trim()] = parts[1].trim()
                }
            }
        }
    }
    return envVars
}

val env = loadEnvFile()

android {
    namespace = "com.example.chatwidgetdemo"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.chatwidgetdemo"
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"

        // Inject environment variables as BuildConfig fields
        // Properly escape strings for Java/Kotlin string literals
        fun escapeString(value: String): String {
            return value.replace("\\", "\\\\")
                       .replace("\"", "\\\"")
                       .replace("\n", "\\n")
                       .replace("\r", "\\r")
                       .replace("\t", "\\t")
        }
        
        buildConfigField("String", "WIDGET_BASE_URL", "\"${escapeString(env["WIDGET_BASE_URL"] ?: "")}\"")
        buildConfigField("String", "WIDGET_APP_ID", "\"${escapeString(env["WIDGET_APP_ID"] ?: "d48c8c5b-f96c-45e0-bb0f-dfbcecd75c6b")}\"")
        buildConfigField("String", "USER_EMAIL", "\"${escapeString(env["USER_EMAIL"] ?: "demo@example.com")}\"")
        buildConfigField("String", "USER_NAME", "\"${escapeString(env["USER_NAME"] ?: "Demo User")}\"")
        buildConfigField("String", "USER_AVATAR_URL", "\"${escapeString(env["USER_AVATAR_URL"] ?: "")}\"")
        buildConfigField("String", "USER_EMAIL_HASH", "\"${escapeString(env["USER_EMAIL_HASH"] ?: "")}\"")
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = "11"
    }
    buildFeatures {
        compose = true
        buildConfig = true
    }
}

dependencies {
    implementation(project(":pylon"))
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.appcompat)
    implementation(libs.material)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.activity.compose)
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.ui.graphics)
    implementation(libs.androidx.compose.ui.tooling.preview)
    implementation(libs.androidx.compose.material3)
    testImplementation(libs.junit)
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)
    androidTestImplementation(platform(libs.androidx.compose.bom))
    androidTestImplementation(libs.androidx.compose.ui.test.junit4)
    debugImplementation(libs.androidx.compose.ui.tooling)
    debugImplementation(libs.androidx.compose.ui.test.manifest)
}