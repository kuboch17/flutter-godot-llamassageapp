package dev.massageflow.app

import android.content.Context
import android.graphics.Color
import android.view.View
import android.widget.FrameLayout
import androidx.fragment.app.FragmentContainerView
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

internal class GodotPlatformViewFactory(
    private val activity: MainActivity,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return GodotPlatformView(activity, viewId)
    }
}

/** A FragmentContainerView exposed to Flutter through hybrid composition. */
private class GodotPlatformView(
    private val activity: MainActivity,
    private val platformViewId: Int,
) : PlatformView, View.OnAttachStateChangeListener {
    private val container = FragmentContainerView(activity).apply {
        id = R.id.godot_fragment_container
        setBackgroundColor(Color.rgb(23, 32, 30))
        layoutParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT,
        )
        addOnAttachStateChangeListener(this@GodotPlatformView)
    }
    private var disposed = false
    private var mounted = false

    override fun getView(): View = container

    override fun onViewAttachedToWindow(view: View) {
        if (!disposed && !mounted) {
            container.post {
                if (!disposed && container.isAttachedToWindow) {
                    activity.mountGodot(platformViewId, container.id)
                    mounted = true
                }
            }
        }
    }

    override fun onViewDetachedFromWindow(view: View) = Unit

    override fun dispose() {
        disposed = true
        container.removeOnAttachStateChangeListener(this)
        if (mounted) {
            activity.unmountGodot(platformViewId)
            mounted = false
        }
    }
}
