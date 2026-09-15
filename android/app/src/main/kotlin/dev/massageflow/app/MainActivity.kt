package dev.massageflow.app

import androidx.annotation.MainThread
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.godotengine.godot.Godot
import org.godotengine.godot.GodotFragment
import org.godotengine.godot.GodotHost
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.GodotPluginRegistry

/**
 * Hosts the Flutter surface and the single GodotFragment allowed in this process.
 */
class MainActivity : FlutterFragmentActivity(), GodotHost {
    companion object {
        private const val VIEW_TYPE = "dev.massageflow/godot_view"
        private const val METHOD_CHANNEL = "dev.massageflow/godot_methods"
        private const val EVENT_CHANNEL = "dev.massageflow/godot_events"
        private const val GODOT_FRAGMENT_TAG = "embedded-godot-fragment"
    }

    private var godotFragment: GodotFragment? = null
    private var bridgePlugin: GodotBridgePlugin? = null
    private var eventSink: EventChannel.EventSink? = null
    private var mountedPlatformViewId: Int? = null
    @Volatile
    private var godotMounted = false

    @Volatile
    private var godotReady = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        flutterEngine.platformViewsController.registry.registerViewFactory(
            VIEW_TYPE,
            GodotPlatformViewFactory(this),
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler(::handleFlutterMethod)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    eventSink = events
                    if (godotReady && godotMounted) {
                        emitBridgeEvent("engine_ready", "{}")
                    }
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }

    private fun handleFlutterMethod(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isEngineReady" -> result.success(godotReady && godotMounted)
            "sendMessage" -> {
                val messageJson = call.arguments as? String
                if (messageJson == null) {
                    result.error("invalid_message", "Expected a JSON string.", null)
                    return
                }

                val plugin = bridgePlugin
                if (!godotReady || !godotMounted || plugin == null) {
                    result.success(false)
                    return
                }

                plugin.sendToGodot(messageJson)
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    @MainThread
    internal fun mountGodot(platformViewId: Int, containerId: Int) {
        if (godotMounted) {
            check(mountedPlatformViewId == platformViewId) {
                "Only one embedded Godot view can be mounted at a time."
            }
            return
        }

        val restored = supportFragmentManager.findFragmentByTag(GODOT_FRAGMENT_TAG)
        if (restored != null && restored !is GodotFragment) {
            supportFragmentManager.beginTransaction()
                .remove(restored)
                .commitNowAllowingStateLoss()
        }

        mountedPlatformViewId = platformViewId
        val fragment = (restored as? GodotFragment) ?: godotFragment
        if (fragment == null) {
            godotReady = false
            val newFragment = GodotFragment()
            godotFragment = newFragment
            supportFragmentManager.beginTransaction()
                .replace(containerId, newFragment, GODOT_FRAGMENT_TAG)
                .commitNowAllowingStateLoss()
        } else {
            godotFragment = fragment
            godotReady = fragment.godot?.runStatus == Godot.RunStatus.STARTED
            if (fragment.isDetached) {
                supportFragmentManager.beginTransaction()
                    .attach(fragment)
                    .commitNowAllowingStateLoss()
            }
        }
        godotMounted = true

        if (godotReady) {
            emitBridgeEvent("engine_ready", "{}")
        }
    }

    @MainThread
    internal fun unmountGodot(platformViewId: Int) {
        if (mountedPlatformViewId != platformViewId) return

        godotFragment?.let { fragment ->
            if (fragment.isAdded && !fragment.isDetached) {
                supportFragmentManager.beginTransaction()
                    .detach(fragment)
                    .commitNowAllowingStateLoss()
            }
        }
        mountedPlatformViewId = null
        godotMounted = false
    }

    override fun getActivity() = this

    override fun getGodot() = godotFragment?.godot

    override fun getCommandLine() = listOf(
        "--disable-godot-splash",
        "--background_color",
        "#17201e",
    )

    override fun getHostPlugins(godot: Godot): Set<GodotPlugin> {
        val registeredPlugin = runCatching {
            GodotPluginRegistry.getPluginRegistry()
                .getPlugin(GodotBridgePlugin.PLUGIN_NAME) as? GodotBridgePlugin
        }.getOrNull()
        val plugin = registeredPlugin
            ?: bridgePlugin
            ?: GodotBridgePlugin(godot, ::emitBridgeEvent)
        plugin.setEventListener(::emitBridgeEvent)
        bridgePlugin = plugin
        return setOf(plugin)
    }

    override fun onGodotSetupCompleted() {
        emitBridgeEvent("engine_setup", "{}")
    }

    override fun onGodotMainLoopStarted() {
        godotReady = true
        if (godotMounted) {
            emitBridgeEvent("engine_ready", "{}")
        }
    }

    private fun emitBridgeEvent(type: String, payloadJson: String) {
        runOnUiThread {
            eventSink?.success(
                mapOf(
                    "type" to type,
                    "payload" to payloadJson,
                ),
            )
        }
    }

    override fun onDestroy() {
        bridgePlugin?.setEventListener(null)
        super.onDestroy()
    }
}
