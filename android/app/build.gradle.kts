plugins {
    id("com.android.application")
    // AGP 9 has built-in Kotlin support. Apply Flutter after Android.
    id("dev.flutter.flutter-gradle-plugin")
}

val godotVersion = providers.gradleProperty("godotVersion").getOrElse("4.7.2.stable")

val embeddedGodotAssets = layout.buildDirectory.dir("generated/godotAssets")
val syncGodotAssets by tasks.registering(Sync::class) {
    from("../../massage-app-")
    into(embeddedGodotAssets)
    exclude(".git/**", ".agents/**", "tools/**", "android/**")
    exclude(".gitignore", ".gitattributes", ".editorconfig", "export_presets.cfg")
    exclude("**/*.apk", "**/*.idsig", "**/*.aab", "**/*.keystore", "**/*.jks")
    exclude(".godot/editor/**", ".godot/exported/**", ".godot/shader_cache/**")
    exclude(".godot/export_credentials.cfg")
    doFirst {
        check(file("../../massage-app-/project.godot").isFile) {
            "Embedded Godot project is missing: massage-app-/project.godot"
        }
    }
}

tasks.named("preBuild") {
    dependsOn(syncGodotAssets)
}

android {
    namespace = "dev.massageflow.app"
    compileSdk {
        version = release(36) {
            minorApiLevel = 1
        }
    }
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "dev.massageflow.app"
        minSdk = 24
        targetSdk = maxOf(flutter.targetSdkVersion, 36)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Package the Godot project at the APK assets root, where GodotFragment
    // discovers project.godot. This keeps Godot source separate from Flutter UI.
    sourceSets.getByName("main").assets.srcDir(embeddedGodotAssets.get().asFile)

    androidResources {
        // Godot can use hidden import metadata. Android's default asset filter
        // would otherwise silently remove it.
        ignoreAssetsPattern =
            "!.svn:!.git:!.gitignore:!.ds_store:!*.scc:<dir>_*:!CVS:!thumbs.db:!picasa.ini:!*~"
    }

    packaging {
        jniLibs {
            pickFirsts += "**/libc++_shared.so"
        }
        resources {
            excludes += setOf("META-INF/LICENSE*", "META-INF/NOTICE*")
        }
    }

    buildTypes {
        release {
            // Replace with a private release signing config before publishing.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("org.godotengine:godot:$godotVersion")
    implementation("androidx.fragment:fragment-ktx:1.8.9")
}
