package com.pylon.chatwidget.flutter

import android.content.Context
import android.view.View
import com.pylon.chatwidget.PylonChat
import com.pylon.chatwidget.PylonChatListener
import com.pylon.chatwidget.PylonConfig
import com.pylon.chatwidget.PylonUser
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

/**
 * Hosts a [PylonChat] view inside Flutter and bridges it to Dart.
 *
 * Method calls arrive from `PylonChatController`; widget events go back out on
 * the same channel, where `PylonChatView` turns them into callbacks and into
 * the hit test regions that let touches pass through to the Flutter app behind
 * the widget.
 */
class PylonChatPlatformView(
    context: Context,
    messenger: BinaryMessenger,
    viewId: Int,
    creationParams: Map<*, *>
) : PlatformView, MethodChannel.MethodCallHandler, PylonChatListener {

    private val channel = MethodChannel(messenger, "$CHANNEL_PREFIX$viewId")

    /** Web view bounds arrive in device pixels; Flutter lays out in logical pixels. */
    private val density = context.resources.displayMetrics.density

    private val chatView: PylonChat
    private var currentUser: PylonUser?
    private var isChatOpen = false

    init {
        currentUser = parseUser(creationParams["user"])
        chatView = PylonChat(context, parseConfig(creationParams["config"]), currentUser)
        chatView.setListener(this)
        channel.setMethodCallHandler(this)
    }

    override fun getView(): View = chatView

    override fun dispose() {
        channel.setMethodCallHandler(null)
        chatView.setListener(null)
        chatView.destroy()
    }

    // MARK: - Dart → native

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "openChat" -> chatView.openChat()
            "closeChat" -> chatView.closeChat()
            "showChatBubble" -> chatView.showChatBubble()
            "hideChatBubble" -> chatView.hideChatBubble()
            "refreshInteractiveBounds" -> chatView.refreshInteractiveBounds()

            "showNewMessage" -> chatView.showNewMessage(
                call.argument<String>("message").orEmpty(),
                call.argument<Boolean>("isHtml") ?: false
            )

            "setNewIssueCustomFields" -> chatView.setNewIssueCustomFields(
                stringKeyedMap(call.argument<Map<*, *>>("fields"))
            )

            "setTicketFormFields" -> chatView.setTicketFormFields(
                stringKeyedMap(call.argument<Map<*, *>>("fields"))
            )

            "showTicketForm" -> chatView.showTicketForm(
                call.argument<String>("slug").orEmpty()
            )

            "showKnowledgeBaseArticle" -> chatView.showKnowledgeBaseArticle(
                call.argument<String>("articleId").orEmpty()
            )

            "updateUser" -> {
                currentUser = parseUser(call.argument<Map<*, *>>("user"))
                chatView.setUser(currentUser)
            }

            "updateEmailHash" -> {
                val user = currentUser
                if (user == null) {
                    result.error(
                        "no_user",
                        "Set a user before setting an email hash.",
                        null
                    )
                    return
                }
                currentUser = user.copy(emailHash = call.argument<String>("emailHash"))
                chatView.setUser(currentUser)
            }

            else -> {
                result.notImplemented()
                return
            }
        }
        result.success(null)
    }

    // MARK: - Native → Dart

    override fun onPylonLoaded() = send("onPylonLoaded")

    override fun onPylonInitialized() = send("onPylonInitialized")

    override fun onPylonReady() = send("onPylonReady")

    override fun onMessageReceived(message: String) =
        send("onMessageReceived", mapOf("message" to message))

    override fun onChatOpened() {
        isChatOpen = true
        send("onChatOpened")
    }

    override fun onChatClosed() {
        val wasOpen = isChatOpen
        isChatOpen = false
        send("onChatClosed", mapOf("wasOpen" to wasOpen))
    }

    override fun onPylonError(error: String) =
        send("onPylonError", mapOf("error" to error))

    override fun onUnreadCountChanged(unreadCount: Int) =
        send("onUnreadCountChanged", mapOf("count" to unreadCount))

    override fun onInteractiveBoundsChanged(
        selector: String,
        left: Float,
        top: Float,
        right: Float,
        bottom: Float
    ) = send(
        // Only a scale is needed here: the WebView lays its content out from its own
        // origin, so the page's coordinates and the view's already share a space.
        // (iOS differs — WKWebView insets its content for the safe area, so the
        // bridge there has to shift the bounds as well.)
        "onInteractiveBoundsChanged",
        mapOf(
            "selector" to selector,
            "left" to (left / density).toDouble(),
            "top" to (top / density).toDouble(),
            "right" to (right / density).toDouble(),
            "bottom" to (bottom / density).toDouble()
        )
    )

    private fun send(method: String, arguments: Map<String, Any?>? = null) {
        channel.invokeMethod(method, arguments)
    }

    // MARK: - Creation params

    private fun parseConfig(raw: Any?): PylonConfig {
        val map = raw as? Map<*, *> ?: error("PylonChatView was created without a config.")
        val appId = map["appId"] as? String
            ?: error("PylonChatView was created without an appId.")

        return PylonConfig.build(appId) {
            enableLogging = map["enableLogging"] as? Boolean ?: true
            debugMode = map["debugMode"] as? Boolean ?: false
            primaryColor = map["primaryColor"] as? String
            (map["widgetBaseUrl"] as? String)?.let { widgetBaseUrl = it }
            (map["widgetScriptUrl"] as? String)?.let { widgetScriptUrl = it }
        }
    }

    private fun parseUser(raw: Any?): PylonUser? {
        val map = raw as? Map<*, *> ?: return null
        val email = map["email"] as? String ?: return null
        val name = map["name"] as? String ?: return null
        return PylonUser(
            email = email,
            name = name,
            avatarUrl = map["avatarUrl"] as? String,
            emailHash = map["emailHash"] as? String,
            accountId = map["accountId"] as? String,
            accountExternalId = map["accountExternalId"] as? String
        )
    }

    private fun stringKeyedMap(raw: Map<*, *>?): Map<String, Any?> {
        if (raw == null) return emptyMap()
        return raw.entries
            .mapNotNull { (key, value) -> (key as? String)?.let { it to value } }
            .toMap()
    }

    companion object {
        /** Must match `_PylonChatViewState._channelPrefix` on the Dart side. */
        private const val CHANNEL_PREFIX = "com.pylon.chatwidget/pylon_chat_view_"
    }
}
