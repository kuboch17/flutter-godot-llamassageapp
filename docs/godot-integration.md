# Godot integration guide

## Project placement

`android/app/build.gradle.kts` stages `../../massage-app-` with `syncGodotAssets`
as an Android asset source, excluding APK exports, credentials, repository data,
and editor caches. Runtime imports and UID/script caches are retained.
Gradle merges the staged directory contents into the root of the APK's
`assets/` directory. Do not place another folder between `massage-app-/` and
`project.godot`.

The sync task changes `run/main_scene` in the staged Android copy to
`res://embedded_runtime.tscn`, warming the body, arrows, and HUD behind the
Flutter menu. The original Godot project still starts at its own menu.
`GodotSessionController` waits for `godot_ready` before sending a pending start.
Flutter displays the scene edge to
edge in landscape, then restores portrait and system UI when returning home.
The `back` button lives in Godot's `UiLayer` and emits `back_to_menu`
through the bridge; Flutter pops the session route. Without the bridge, the
button opens Godot's own `main.tscn`. The scene skips window/orientation changes
when embedded. `camera_zoom_out` in `cube_scene.gd` controls the wider camera
framing (default 1.6).

`start_session` removes the previous instance and instantiates a fresh massage
scene from the cached PackedScene. `stop_session` disables processing and hides
the Godot UI while the Flutter menu covers the viewport. `request_exit` requests
an immediate return to the menu, just like Godot's back button, including
Android system back. The timer starts automatically after the camera entrance.
App backgrounding pauses time and animation. Two authored arrow groups alternate
every 30 seconds for ten intervals; completion stops at exactly 300 seconds.

The reference HUD contains only back, top progress, `MM:SS` remaining time,
and sound. It has no ready card, position label, exit confirmation, or completion
button. Camera placement solves the projected arrow bounds so their center lies
halfway between the progress bar's bottom edge and the viewport's bottom edge,
including mirrored paths and perspective depth. The sound button controls
Godot's Master audio bus and restores its previous mute state when leaving.

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
  "action": "start_session",
  "payload": {}
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
- A single Godot platform view is mounted in the MaterialApp builder at startup
  and stays mounted behind the Navigator. The menu covers it; session routes
  hide the Flutter layer and allow Godot to receive touches. Navigation never
  replaces the engine. The runtime replaces only the massage scene.
- Android also hides the native fragment view while in the menu. SurfaceView
  rendering can otherwise appear above Flutter's menu regardless of Stack
  order. The surface becomes visible before `start_session` is delivered.
- Directly running `embedded_runtime.tscn` without a Flutter bridge starts an
  active scene with its HUD; only embedded menu preloading hides and disables it.
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
