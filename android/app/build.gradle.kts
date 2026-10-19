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
    doLast {
        // Flutter owns the menu; the embedded engine starts directly in 3D.
        val project = embeddedGodotAssets.get().file("project.godot").asFile
        project.writeText(
            project.readText().replace(
                "run/main_scene=\"res://main.tscn\"",
                "run/main_scene=\"res://embedded_runtime.tscn\"",
            ).replace(
                "window/handheld/orientation=6",
                "window/handheld/orientation=1", // Preload behind the portrait menu.
            ).replace(
                "window/size/viewport_width=1080",
                "window/size/viewport_width=1920",
            ).replace(
                "window/size/viewport_height=1920",
                "window/size/viewport_height=1080",
            ),
        )
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

androidComponents {
    finalizeDsl { androidDsl ->
        // Flutter selects the phone's ABI, but its default filters still package
        // Godot's native libraries for every architecture unless narrowed here.
        val requestedAbis = providers.gradleProperty("target-platform").orNull
            ?.split(",")
            ?.mapNotNull { platform ->
                when (platform.trim()) {
                    "android-arm" -> "armeabi-v7a"
                    "android-arm64" -> "arm64-v8a"
                    "android-x64" -> "x86_64"
                    else -> null
                }
            }
        if (!androidDsl.splits.abi.isEnable && !requestedAbis.isNullOrEmpty()) {
            androidDsl.defaultConfig.ndk.abiFilters.clear()
            androidDsl.defaultConfig.ndk.abiFilters.addAll(requestedAbis)
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("org.godotengine:godot:$godotVersion")
    implementation("androidx.fragment:fragment-ktx:1.8.9")
}
