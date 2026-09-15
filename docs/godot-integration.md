# Godot integration guide

## Project placement

`android/app/build.gradle.kts` registers `../../godot_project` as an Android
asset source. Gradle merges the directory contents into the root of the APK's
`assets/` directory. Do not place another folder between `godot_project/` and
`project.godot`.

Using source assets instead of a prebuilt PCK keeps iteration simple and makes
the Godot portion reviewable on GitHub. A production project may switch to a
PCK by packaging it in Android assets and returning
`["--main-pack", "res://module.pck"]` from `MainActivity.getCommandLine()`.

The Android build does not run Godot's editor import pipeline. If the project
uses textures, models, audio, or other imported resources, open it in the
matching Godot editor and commit the required `.godot/imported/` outputs (the
official embedded sample follows this model), or export a PCK as a separate CI
step. Editor UI and shader-cache directories remain ignored.

## Message contract

Flutter sends this JSON string over the method channel:

```json
{
  "action": "configure",
  "payload": {
    "technique": "Slow circular pressure",
    "durationSeconds": 300
  }
}
```

Kotlin emits it as the `flutter_message(message_json: String)` signal on the
runtime singleton named `FlutterGodotBridge`.

Godot sends events back by calling:

```gdscript
var bridge = Engine.get_singleton("FlutterGodotBridge")
bridge.sendToFlutter("interaction", JSON.stringify({"count": 1}))
```

Flutter receives a platform map whose `type` identifies the event and whose
`payload` contains a JSON object string. Keeping the native bridge unaware of
domain models makes it straightforward to evolve the massage experience.

## Lifecycle and rendering

- `MainActivity` extends `FlutterFragmentActivity` because `GodotFragment`
  needs an AndroidX fragment host.
- Flutter uses `PlatformViewLink` + `AndroidViewSurface`, selecting hybrid
  composition for Godot's native surface and touch input.
- The Godot fragment is created when the first session widget attaches. When
  Flutter disposes the platform view, the fragment is detached (its view is
  destroyed, but its engine instance is retained) and later reattached.
- Only one view is supported at a time, matching Godot's single engine instance
  per process limitation. The fragment is finally destroyed with the activity.
- The manifest declares all relevant configuration changes so Android does not
  recreate the activity merely for rotation, density, locale, or UI-mode
  updates while Godot is running.

## Integrating a larger project

Check these items before copying an existing project:

- Use a Godot Android AAR matching the project's major/minor engine version.
- Prefer the Mobile or Compatibility renderer for a view-sized mobile module.
- Enable ETC2/ASTC texture import for Android.
- Do not package desktop-only GDExtension binaries. Add arm64-v8a and any other
  supported Android ABI explicitly.
- Namespace Godot autoloads and Android plugin singleton names to prevent
  collisions with `FlutterGodotBridge`.
- Avoid calling `get_tree().quit()` for ordinary Flutter navigation; let the
  Android host own teardown.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Black view | Confirm `project.godot` is at the asset root and has a valid `run/main_scene`. |
| Flutter controls visible but no touch in Godot | Keep the eager gesture recognizer in `GodotView`. |
| `Engine.get_singleton(...)` is null | Confirm `MainActivity` implements `GodotHost` and returns the runtime plugin. |
| Native library merge failure | Inspect GDExtension ABIs and the `libc++_shared.so` packaging rule. |
| Crash on rotation | Keep the manifest `configChanges` list or lock the activity orientation. |
| Bridge command returns `false` | Wait for `engine_ready`/`godot_ready` before sending it. |
