package com.pylonchat.reactnative

import android.content.Context
import android.view.MotionEvent
import android.view.ViewGroup
import android.widget.FrameLayout
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.RCTEventEmitter
import com.pylon.chatwidget.PylonChatListener
import com.pylon.chatwidget.PylonChatView
import com.pylon.chatwidget.PylonConfig
import com.pylon.chatwidget.PylonUser

/**
 * React Native wrapper for PylonChatView.
 * This is kept as minimal as possible to avoid interfering with touch pass-through.
 */
class RNPylonChatView(context: Context) : FrameLayout(context) {
    
    private var pylonChatView: PylonChatView? = null
    private var config: PylonConfig? = null
    private var user: PylonUser? = null
    
    // Config properties
    var appId: String? = null
        set(value) {
            field = value
            updateConfig()
        }
    
    var widgetBaseUrl: String? = null
        set(value) {
            field = value
            updateConfig()
        }
    
    var widgetScriptUrl: String? = null
        set(value) {
            field = value
            updateConfig()
        }
    
    var enableLogging: Boolean = true
        set(value) {
            field = value
            updateConfig()
        }
    
    var debugMode: Boolean = false
        set(value) {
            field = value
            updateConfig()
        }
    
    var primaryColor: String? = null
        set(value) {
            field = value
            updateConfig()
        }
    
    // User properties
    var userEmail: String? = null
        set(value) {
            field = value
            updateUser()
        }
    
    var userName: String? = null
        set(value) {
            field = value
            updateUser()
        }
    
    var userAvatarUrl: String? = null
        set(value) {
            field = value
            updateUser()
        }
    
    var userEmailHash: String? = null
        set(value) {
            field = value
            updateUser()
        }
    
    var userAccountId: String? = null
        set(value) {
            field = value
            updateUser()
        }
    
    var userAccountExternalId: String? = null
        set(value) {
            field = value
            updateUser()
        }

    init {
        layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
    }
    
    // Track pointer events setting
    private var pointerEventsMode = "auto"
    
    fun setPointerEventsMode(mode: String) {
        pointerEventsMode = mode
    }
    
    /**
     * This is the CRITICAL method for pointerEvents.
     * By returning false here when pointerEvents="none", we tell React Native's
     * touch system to pass the touch to views BEHIND this one, not just children.
     */
    override fun dispatchTouchEvent(ev: MotionEvent): Boolean {
        when (pointerEventsMode) {
            "none" -> {
                // Don't handle ANY touches - pass through to views BEHIND this one
                return false
            }
            "box-none" -> {
                // This view doesn't handle touches, but children can
                // Try children first, if they don't handle it, pass through
                val handled = super.dispatchTouchEvent(ev)
                return handled  // If children didn't handle it, return false passes through
            }
            "box-only" -> {
                // Only this view handles touches, not children
                // Don't dispatch to children
                return onTouchEvent(ev)
            }
            else -> {
                // "auto" - normal behavior
                return super.dispatchTouchEvent(ev)
            }
        }
    }

    private fun updateConfig() {
        val id = appId ?: return
        
        config = PylonConfig.build(id) {
            this.enableLogging = this@RNPylonChatView.enableLogging
            this.primaryColor = this@RNPylonChatView.primaryColor
            this.debugMode = this@RNPylonChatView.debugMode
            this@RNPylonChatView.widgetBaseUrl?.let { this.widgetBaseUrl = it }
            this@RNPylonChatView.widgetScriptUrl?.let { this.widgetScriptUrl = it }
        }
        
        recreatePylonView()
    }
    
    private fun updateUser() {
        val email = userEmail ?: return
        val name = userName ?: return
        
        user = PylonUser(
            email = email,
            name = name,
            avatarUrl = userAvatarUrl,
            emailHash = userEmailHash,
            accountId = userAccountId,
            accountExternalId = userAccountExternalId
        )
        
        recreatePylonView()
    }
    
    private fun recreatePylonView() {
        val cfg = config ?: return
        val usr = user ?: return
        
        // Remove old view
        pylonChatView?.let { removeView(it) }
        
        // Create new PylonChatView
        val newView = PylonChatView(context, cfg, usr)
        newView.setListener(object : PylonChatListener {
            override fun onPylonLoaded() {
                sendEvent("onPylonLoaded", Arguments.createMap())
            }
            
            override fun onPylonInitialized() {
                sendEvent("onPylonInitialized", Arguments.createMap())
            }
            
            override fun onPylonReady() {
                sendEvent("onPylonReady", Arguments.createMap())
            }
            
            override fun onMessageReceived(message: String) {
                val params = Arguments.createMap()
                params.putString("message", message)
                sendEvent("onMessageReceived", params)
            }
            
            override fun onChatOpened() {
                sendEvent("onChatOpened", Arguments.createMap())
            }
            
            override fun onChatClosed() {
                val params = Arguments.createMap()
                params.putBoolean("wasOpen", true)
                sendEvent("onChatClosed", params)
            }
            
            override fun onInteractiveBoundsChanged(selector: String, left: Float, top: Float, right: Float, bottom: Float) {
                // Convert pixels to density-independent pixels (dp) for React Native.
                val density = resources.displayMetrics.density
                val params = Arguments.createMap()
                params.putString("selector", selector)
                params.putDouble("left", (left / density).toDouble())
                params.putDouble("top", (top / density).toDouble())
                params.putDouble("right", (right / density).toDouble())
                params.putDouble("bottom", (bottom / density).toDouble())
                sendEvent("onInteractiveBoundsChanged", params)
            }
            
            override fun onPylonError(error: String) {
                val params = Arguments.createMap()
                params.putString("error", error)
                sendEvent("onPylonError", params)
            }
            
            override fun onUnreadCountChanged(count: Int) {
                val params = Arguments.createMap()
                params.putInt("count", count)
                sendEvent("onUnreadCountChanged", params)
            }
            
            override fun onFileChooserLaunched(requestCode: Int) {
                // Handle file chooser if needed
            }
        })
        
        newView.layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
        addView(newView)
        pylonChatView = newView
    }
    
    private fun sendEvent(eventName: String, params: WritableMap) {
        val reactContext = context as ReactContext
        reactContext
            .getJSModule(RCTEventEmitter::class.java)
            .receiveEvent(id, eventName, params)
    }
    
    // Imperative methods
    fun openChat() {
        pylonChatView?.openChat()
    }
    
    fun closeChat() {
        pylonChatView?.closeChat()
    }
    
    fun showChatBubble() {
        pylonChatView?.showChatBubble()
    }
    
    fun hideChatBubble() {
        pylonChatView?.hideChatBubble()
    }
    
    fun showNewMessage(message: String, isHtml: Boolean) {
        pylonChatView?.showNewMessage(message, isHtml)
    }
    
    fun setNewIssueCustomFields(fields: Map<String, Any?>) {
        @Suppress("UNCHECKED_CAST")
        pylonChatView?.setNewIssueCustomFields(fields as Map<String, Any>)
    }

    fun setTicketFormFields(fields: Map<String, Any?>) {
        @Suppress("UNCHECKED_CAST")
        pylonChatView?.setTicketFormFields(fields as Map<String, Any>)
    }
    
    fun updateEmailHash(emailHash: String?) {
        pylonChatView?.setEmailHash(emailHash)
    }
    
    fun showTicketForm(slug: String) {
        pylonChatView?.showTicketForm(slug)
    }
    
    fun showKnowledgeBaseArticle(articleId: String) {
        pylonChatView?.showKnowledgeBaseArticle(articleId)
    }
    
    fun clickElementAtSelector(selector: String) {
        // Trigger a click on the element with the given ID selector.
        // This is used for Android's proxy-based touch pass-through system.
        pylonChatView?.clickElementBySelector(selector)
    }
}

