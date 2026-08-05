package com.pylon.chatwidget.flutter

import android.app.Activity
import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/** Creates a [PylonChatPlatformView] for each `PylonChatView` widget. */
class PylonChatViewFactory(
    private val messenger: BinaryMessenger
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    /** Set by [PylonChatPlugin] as the Activity comes and goes. */
    var activity: Activity? = null

    override fun create(context: Context?, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as? Map<*, *> ?: emptyMap<String, Any?>()
        // PylonChat walks its Context to find the hosting Activity — it needs one to
        // start the file picker and to read IME insets — so prefer the real Activity
        // over whatever context the embedder hands us.
        val viewContext = activity
            ?: context
            ?: error("Cannot create PylonChatView without a Context.")
        return PylonChatPlatformView(viewContext, messenger, viewId, creationParams)
    }
}
