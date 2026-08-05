package com.pylon.chatwidget.flutter

import com.pylon.chatwidget.PylonChat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener

/**
 * Registers the Pylon chat widget as a Flutter platform view.
 *
 * The plugin also tracks the hosting Activity, which the SDK needs in order to
 * launch the file picker for chat attachments and to observe keyboard insets.
 */
class PylonChatPlugin : FlutterPlugin, ActivityAware {

    private var viewFactory: PylonChatViewFactory? = null
    private var activityBinding: ActivityPluginBinding? = null

    private val activityResultListener = ActivityResultListener { requestCode, resultCode, data ->
        if (requestCode != FILE_CHOOSER_REQUEST_CODE) {
            false
        } else {
            PylonChat.handleActivityResult(resultCode, data)
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val factory = PylonChatViewFactory(binding.binaryMessenger)
        viewFactory = factory
        binding.platformViewRegistry.registerViewFactory(VIEW_TYPE, factory)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        viewFactory = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        attachActivity(binding)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        attachActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachActivity()
    }

    override fun onDetachedFromActivity() {
        detachActivity()
    }

    private fun attachActivity(binding: ActivityPluginBinding) {
        detachActivity()
        activityBinding = binding
        binding.addActivityResultListener(activityResultListener)
        viewFactory?.activity = binding.activity
    }

    private fun detachActivity() {
        activityBinding?.removeActivityResultListener(activityResultListener)
        activityBinding = null
        viewFactory?.activity = null
    }

    companion object {
        /** Must match `_PylonChatViewState._viewType` on the Dart side. */
        const val VIEW_TYPE = "com.pylon.chatwidget/pylon_chat_view"

        /** Mirrors PylonChat's own (private) file chooser request code. */
        private const val FILE_CHOOSER_REQUEST_CODE = 0x5043
    }
}
