package com.pylonchat.reactnative

import android.graphics.Color
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.common.MapBuilder
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.uimanager.events.RCTEventEmitter
import com.pylon.chatwidget.PylonChatListener
import com.pylon.chatwidget.PylonChatView
import com.pylon.chatwidget.PylonConfig
import com.pylon.chatwidget.PylonUser

class RNPylonChatViewManager : SimpleViewManager<RNPylonChatView>() {
    
    companion object {
        const val REACT_CLASS = "RNPylonChatView"
        const val COMMAND_OPEN_CHAT = 1
        const val COMMAND_CLOSE_CHAT = 2
        const val COMMAND_SHOW_BUBBLE = 3
        const val COMMAND_HIDE_BUBBLE = 4
        const val COMMAND_SHOW_NEW_MESSAGE = 5
        const val COMMAND_SET_CUSTOM_FIELDS = 6
        const val COMMAND_SET_TICKET_FIELDS = 7
        const val COMMAND_UPDATE_EMAIL_HASH = 8
        const val COMMAND_SHOW_TICKET_FORM = 9
        const val COMMAND_SHOW_KB_ARTICLE = 10
        const val COMMAND_CLICK_ELEMENT_AT_SELECTOR = 11
    }

    override fun getName(): String = REACT_CLASS

    override fun createViewInstance(reactContext: ThemedReactContext): RNPylonChatView {
        return RNPylonChatView(reactContext)
    }

    // Config props
    @ReactProp(name = "appId")
    fun setAppId(view: RNPylonChatView, appId: String?) {
        view.appId = appId
    }

    @ReactProp(name = "widgetBaseUrl")
    fun setWidgetBaseUrl(view: RNPylonChatView, url: String?) {
        view.widgetBaseUrl = url
    }

    @ReactProp(name = "widgetScriptUrl")
    fun setWidgetScriptUrl(view: RNPylonChatView, url: String?) {
        view.widgetScriptUrl = url
    }

    @ReactProp(name = "enableLogging")
    fun setEnableLogging(view: RNPylonChatView, enabled: Boolean) {
        view.enableLogging = enabled
    }

    @ReactProp(name = "debugMode")
    fun setDebugMode(view: RNPylonChatView, enabled: Boolean) {
        view.debugMode = enabled
    }

    @ReactProp(name = "pointerEvents")
    fun setPointerEvents(view: RNPylonChatView, pointerEvents: String?) {
        val mode = pointerEvents ?: "auto"
        view.setPointerEventsMode(mode)
        
        when (mode) {
            "none" -> {
                // Don't handle any touches - let them pass through
                view.isClickable = false
                view.isFocusable = false
            }
            "auto" -> {
                // Handle touches normally
                view.isClickable = true
                view.isFocusable = true
            }
            "box-none" -> {
                // Only children can handle touches, not this view itself
                view.isClickable = false
                view.isFocusable = false
            }
            "box-only" -> {
                // Only this view handles touches, not children
                view.isClickable = true
                view.isFocusable = true
            }
        }
    }

    @ReactProp(name = "primaryColor")
    fun setPrimaryColor(view: RNPylonChatView, color: String?) {
        view.primaryColor = color
    }

    // User props
    @ReactProp(name = "userEmail")
    fun setUserEmail(view: RNPylonChatView, email: String?) {
        view.userEmail = email
    }

    @ReactProp(name = "userName")
    fun setUserName(view: RNPylonChatView, name: String?) {
        view.userName = name
    }

    @ReactProp(name = "userAvatarUrl")
    fun setUserAvatarUrl(view: RNPylonChatView, url: String?) {
        view.userAvatarUrl = url
    }

    @ReactProp(name = "userEmailHash")
    fun setUserEmailHash(view: RNPylonChatView, hash: String?) {
        view.userEmailHash = hash
    }

    @ReactProp(name = "userAccountId")
    fun setUserAccountId(view: RNPylonChatView, id: String?) {
        view.userAccountId = id
    }

    @ReactProp(name = "userAccountExternalId")
    fun setUserAccountExternalId(view: RNPylonChatView, id: String?) {
        view.userAccountExternalId = id
    }

    // Event names
    override fun getExportedCustomDirectEventTypeConstants(): MutableMap<String, Any> {
        return MapBuilder.builder<String, Any>()
            .put("onPylonLoaded", MapBuilder.of("registrationName", "onPylonLoaded"))
            .put("onPylonInitialized", MapBuilder.of("registrationName", "onPylonInitialized"))
            .put("onPylonReady", MapBuilder.of("registrationName", "onPylonReady"))
            .put("onChatOpened", MapBuilder.of("registrationName", "onChatOpened"))
            .put("onChatClosed", MapBuilder.of("registrationName", "onChatClosed"))
            .put("onUnreadCountChanged", MapBuilder.of("registrationName", "onUnreadCountChanged"))
            .put("onMessageReceived", MapBuilder.of("registrationName", "onMessageReceived"))
            .put("onPylonError", MapBuilder.of("registrationName", "onPylonError"))
            .put("onInteractiveBoundsChanged", MapBuilder.of("registrationName", "onInteractiveBoundsChanged"))
            .build() as MutableMap<String, Any>
    }

    // Commands
    override fun getCommandsMap(): MutableMap<String, Int> {
        return MapBuilder.builder<String, Int>()
            .put("openChat", COMMAND_OPEN_CHAT)
            .put("closeChat", COMMAND_CLOSE_CHAT)
            .put("showChatBubble", COMMAND_SHOW_BUBBLE)
            .put("hideChatBubble", COMMAND_HIDE_BUBBLE)
            .put("showNewMessage", COMMAND_SHOW_NEW_MESSAGE)
            .put("setNewIssueCustomFields", COMMAND_SET_CUSTOM_FIELDS)
            .put("setTicketFormFields", COMMAND_SET_TICKET_FIELDS)
            .put("updateEmailHash", COMMAND_UPDATE_EMAIL_HASH)
            .put("showTicketForm", COMMAND_SHOW_TICKET_FORM)
            .put("showKnowledgeBaseArticle", COMMAND_SHOW_KB_ARTICLE)
            .put("clickElementAtSelector", COMMAND_CLICK_ELEMENT_AT_SELECTOR)
            .build() as MutableMap<String, Int>
    }

    override fun receiveCommand(view: RNPylonChatView, commandId: String, args: ReadableArray?) {
        when (commandId) {
            "openChat" -> view.openChat()
            "closeChat" -> view.closeChat()
            "showChatBubble" -> view.showChatBubble()
            "hideChatBubble" -> view.hideChatBubble()
            "showNewMessage" -> {
                val message = args?.getString(0) ?: return
                val isHtml = args.getBoolean(1)
                view.showNewMessage(message, isHtml)
            }
            "setNewIssueCustomFields" -> {
                val fields = args?.getMap(0) ?: return
                view.setNewIssueCustomFields(fields.toHashMap())
            }
            "setTicketFormFields" -> {
                val fields = args?.getMap(0) ?: return
                view.setTicketFormFields(fields.toHashMap())
            }
            "updateEmailHash" -> {
                val hash = args?.getString(0)
                view.updateEmailHash(hash)
            }
            "showTicketForm" -> {
                val slug = args?.getString(0) ?: return
                view.showTicketForm(slug)
            }
            "showKnowledgeBaseArticle" -> {
                val articleId = args?.getString(0) ?: return
                view.showKnowledgeBaseArticle(articleId)
            }
            "clickElementAtSelector" -> {
                val selector = args?.getString(0) ?: return
                view.clickElementAtSelector(selector)
            }
        }
    }
}

