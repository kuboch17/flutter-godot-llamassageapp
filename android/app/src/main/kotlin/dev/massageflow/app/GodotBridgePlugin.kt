package dev.massageflow.app

import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot

/**
 * Runtime Godot plugin that keeps Flutter and GDScript decoupled by passing
 * JSON envelopes in both directions.
 */
internal class GodotBridgePlugin(
    godot: Godot,
    eventListener: (type: String, payloadJson: String) -> Unit,
) : GodotPlugin(godot) {
    companion object {
        const val PLUGIN_NAME = "FlutterGodotBridge"
        val FLUTTER_MESSAGE_SIGNAL = SignalInfo("flutter_message", String::class.java)
    }

    override fun getPluginName() = PLUGIN_NAME

    override fun getPluginSignals() = setOf(FLUTTER_MESSAGE_SIGNAL)

    @Volatile
    private var eventListener: ((type: String, payloadJson: String) -> Unit)? = eventListener

    internal fun setEventListener(
        listener: ((type: String, payloadJson: String) -> Unit)?,
    ) {
        eventListener = listener
    }

    internal fun sendToGodot(messageJson: String) {
        emitSignal(FLUTTER_MESSAGE_SIGNAL.name, messageJson)
    }

    /** Called from GDScript via Engine.get_singleton(PLUGIN_NAME). */
    @UsedByGodot
    fun sendToFlutter(type: String, payloadJson: String) {
        runOnHostThread {
            eventListener?.invoke(type, payloadJson.ifBlank { "{}" })
        }
    }
}
