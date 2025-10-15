package com.example.probe

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Rect
import android.net.Uri
import android.util.AttributeSet
import android.util.Log
import android.view.MotionEvent
import android.view.View
import android.webkit.ConsoleMessage
import android.webkit.JavascriptInterface
import android.webkit.JsResult
import android.webkit.ValueCallback
import android.webkit.WebChromeClient
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
import androidx.core.net.toUri
import org.json.JSONObject

/**
 * Custom WebView widget for Probe (Pylon) Chat
 */
@SuppressLint("SetJavaScriptEnabled")
class PylonChat @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : FrameLayout(context, attrs, defStyleAttr) {

    companion object {
        private const val TAG = "ProbeWidget"
        private const val FILE_CHOOSER_REQUEST_CODE = 0x5043 // "PC" in hex

        enum class InteractiveElementId(val selector: String) {
            FAB("pylon-chat-bubble"),
            SURVEY("pylon-chat-popup-survey"),
            MESSAGE("pylon-chat-popup-message")
        }

        private var activeFilePathCallback: ValueCallback<Array<Uri>>? = null

        /**
         * Handle the file chooser result. Call this from your Activity's onActivityResult
         * or from the ActivityResultLauncher callback.
         */
        @Deprecated("Use handleActivityResult instead", ReplaceWith("handleActivityResult(resultCode, data)"))
        @JvmStatic
        fun handleFileChooserResult(resultCode: Int, data: Intent?) {
            handleActivityResult(resultCode, data)
        }

        /**
         * Consume an activity result if it belongs to a pending file picker request.
         * Returns true when the SDK handled the result.
         */
        @JvmStatic
        fun handleActivityResult(resultCode: Int, data: Intent?): Boolean {
            val callback = activeFilePathCallback
            activeFilePathCallback = null

            if (callback == null) {
                Log.w(TAG, "No active file chooser callback")
                return false
            }

            if (resultCode == Activity.RESULT_OK && data != null) {
                val result = when {
                    data.dataString != null -> arrayOf(data.dataString!!.toUri())
                    data.clipData != null -> {
                        val count = data.clipData!!.itemCount
                        Array(count) { i -> data.clipData!!.getItemAt(i).uri }
                    }
                    data.data != null -> arrayOf(data.data!!)
                    else -> null
                }
                callback.onReceiveValue(result)
            } else {
                callback.onReceiveValue(null)
            }

            return true
        }
    }

    private val webView: WebView = WebView(context).apply {
        layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
    }
    private var listener: PylonChatListener? = null
    private var hasStartedLoading = false
    private var isLoaded = false
    private var isChatWindowOpen = false

    private val interactiveBounds = InteractiveElementId.entries
        .associate { it.selector to Rect() }
        .toMap()

    private val debugOverlay = DebugOverlayView(context).apply {
        layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
        visibility = View.GONE
    }

    init {
        addView(webView)
        if (Pylon.requireConfig().debugMode) {
            addView(debugOverlay)
            debugOverlay.visibility = View.VISIBLE
            debugOverlay.bounds = interactiveBounds
        }
        setupWebView()
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        ensureProbeLoaded()
    }

    override fun dispatchTouchEvent(ev: MotionEvent): Boolean {
        if (isChatWindowOpen) {
            return super.dispatchTouchEvent(ev)
        }

        val (x, y) = ev.x.toInt() to ev.y.toInt()
        val shouldHandleTap = interactiveBounds.any { (_, bounds) ->
            !bounds.isEmpty && bounds.contains(x, y)
        }

        return if (shouldHandleTap) {
            super.dispatchTouchEvent(ev)
        } else {
            false
        }
    }

    private fun setupWebView() {
        WebView.setWebContentsDebuggingEnabled(true)
        webView.fitsSystemWindows = true
        webView.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            databaseEnabled = true
            allowFileAccess = true
            allowContentAccess = true
            setLayerType(View.LAYER_TYPE_HARDWARE, null)
            useWideViewPort = true
            loadWithOverviewMode = true
            cacheMode = WebSettings.LOAD_DEFAULT
            mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
            javaScriptCanOpenWindowsAutomatically = true
            setSupportMultipleWindows(true)
            allowFileAccessFromFileURLs = true
            allowUniversalAccessFromFileURLs = true
            mediaPlaybackRequiresUserGesture = false
            setSupportZoom(false)
            builtInZoomControls = false
            displayZoomControls = false
        }

        webView.setBackgroundColor(Color.TRANSPARENT)

        webView.webViewClient = object : WebViewClient() {
            override fun onPageFinished(view: WebView?, url: String?) {
                super.onPageFinished(view, url)
                Log.d(TAG, "Page finished loading: $url")

                if (!isLoaded) {
                    isLoaded = true
                    initializeProbe()
                    listener?.onProbeLoaded()
                }
            }

            override fun onReceivedError(view: WebView?, request: WebResourceRequest?, error: WebResourceError?) {
                super.onReceivedError(view, request, error)
                val errorMsg = error?.description?.toString() ?: "Unknown error"
                Log.e(TAG, "WebView Error: $errorMsg")
                listener?.onProbeError(errorMsg)
            }
        }

        webView.webChromeClient = object : WebChromeClient() {
            override fun onConsoleMessage(consoleMessage: ConsoleMessage?): Boolean {
                consoleMessage?.let { msg ->
                    val config = Pylon.requireConfig()
                    if (config.enableLogging) {
                        val logMessage = "[${msg.messageLevel()}] ${msg.sourceId()}:${msg.lineNumber()} - ${msg.message()}"
                        Log.d(TAG, logMessage)
                    }
                }
                return true
            }

            override fun onJsAlert(view: WebView?, url: String?, message: String?, result: JsResult?): Boolean {
                Log.e(TAG, "Alert: $message from $url")
                return super.onJsAlert(view, url, message, result)
            }

            override fun onCreateWindow(view: WebView?, isDialog: Boolean, isUserGesture: Boolean, resultMsg: android.os.Message?): Boolean {
                val href = view?.handler?.obtainMessage()
                view?.requestFocusNodeHref(href)

                href?.let {
                    val url = it.data.getString("url")
                    if (!url.isNullOrEmpty()) {
                        val intent = Intent(Intent.ACTION_VIEW, url.toUri())
                        context.startActivity(intent)
                    }
                }

                return true
            }

            override fun onShowFileChooser(
                webView: WebView?,
                filePathCallback: ValueCallback<Array<Uri>>?,
                fileChooserParams: FileChooserParams?
            ): Boolean {
                activeFilePathCallback?.onReceiveValue(null)
                activeFilePathCallback = filePathCallback

                val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    val acceptTypes = fileChooserParams?.acceptTypes
                    type = when {
                        acceptTypes.isNullOrEmpty() -> "*/*"
                        acceptTypes.size == 1 -> acceptTypes[0].ifEmpty { "*/*" }
                        else -> "*/*"
                    }
                    if (fileChooserParams?.mode == FileChooserParams.MODE_OPEN_MULTIPLE) {
                        putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
                    }
                }

                val chooserIntent = Intent.createChooser(intent, "Choose File")

                return try {
                    if (context is Activity) {
                        (context as Activity).startActivityForResult(chooserIntent, FILE_CHOOSER_REQUEST_CODE)
                    } else {
                        chooserIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        context.startActivity(chooserIntent)
                        Log.w(
                            TAG,
                            "File chooser launched from non-Activity context. " +
                                "Developers should call PylonChat.handleFileChooserResult() " +
                                "from their Activity's onActivityResult or use ActivityResultLauncher"
                        )
                        listener?.onFileChooserLaunched(FILE_CHOOSER_REQUEST_CODE)
                    }
                    true
                } catch (e: Exception) {
                    Log.e(TAG, "Cannot open file chooser", e)
                    filePathCallback?.onReceiveValue(null)
                    activeFilePathCallback = null
                    false
                }
            }
        }

        webView.addJavascriptInterface(ProbeJSInterface(), "ProbeNative")
    }

    private fun findInteractiveElementPosition(selector: String) {
        val jsCode = """
            javascript:(function() {
                var element = document.querySelector('[id="$selector"]');
                var dpr = window.devicePixelRatio || 1;
                var rect = element ? element.getBoundingClientRect() : null;
                
                if (rect !== null && rect.width > 0) {
                    window.ProbeNative.updateInteractiveBounds(
                        "$selector",
                        rect.left * dpr,
                        rect.top * dpr,
                        rect.right * dpr,
                        rect.bottom * dpr
                    );
                } else {
                    window.ProbeNative.updateInteractiveBounds(
                        "$selector", 0, 0, 0, 0
                    );
                }
            })();
        """.trimIndent()

        webView.evaluateJavascript(jsCode, null)
    }

    /**
     * Public API to force loading (or reloading) the probe HTML manually.
     */
    fun loadProbe(forceReload: Boolean = false) {
        ensureProbeLoaded(forceReload)
    }

    internal fun ensureProbeLoaded(forceReload: Boolean = false) {
        if (forceReload) {
            hasStartedLoading = false
            isLoaded = false
        }

        if (hasStartedLoading) return

        val config = Pylon.requireConfig()
        val user = Pylon.currentUser()
        val html = generateHtml(config, user)
        hasStartedLoading = true
        webView.loadDataWithBaseURL(
            config.widgetBaseUrl,
            html,
            "text/html",
            "UTF-8",
            null
        )
    }

    private fun initializeProbe() {
        val config = Pylon.requireConfig()
        val user = Pylon.currentUser()

        val settingsObject = buildChatSettings(config, user)
        val jsCode = """
            javascript:(function() {
                if (!window.pylon) {
                    window.pylon = {};
                }
                window.pylon.chat_settings = $settingsObject;
                
                if (window.Pylon) {
                    window.Pylon('onShow', function() {
                        window.ProbeNative.onChatWindowOpened();
                    });
                    
                    window.Pylon('onHide', function() {
                        window.ProbeNative.onChatWindowClosed();
                    });
                    
                    window.Pylon('onShowChatBubble', function() {
                        window.ProbeNative.onInteractiveElementUpdate('${InteractiveElementId.FAB.selector}');
                        window.ProbeNative.onInteractiveElementUpdate('${InteractiveElementId.MESSAGE.selector}');
                    });
                    
                    window.Pylon('onHideChatBubble', function() {
                        window.ProbeNative.onInteractiveElementUpdate('${InteractiveElementId.FAB.selector}');
                        window.ProbeNative.onInteractiveElementUpdate('${InteractiveElementId.MESSAGE.selector}');
                    });
                    
                    window.Pylon('onPopupSurveyVisibilityChange', function(isShowing) {
                        window.ProbeNative.onInteractiveElementUpdate('${InteractiveElementId.SURVEY.selector}');
                    });
                    
                    window.Pylon('onPopupMessageVisibilityChange', function(isShowing) {
                        window.ProbeNative.onInteractiveElementUpdate('${InteractiveElementId.MESSAGE.selector}');
                    });
                    
                    window.Pylon('onChangeUnreadMessagesCount', function(unreadCount) {
                        window.ProbeNative.onUnreadCountChanged(unreadCount);
                    });
                }
                
                if (window.ProbeNative) {
                    window.ProbeNative.onInitialized();
                }
                
                console.log('Probe initialized with user:', window.pylon.chat_settings);
            })();
        """.trimIndent()

        webView.evaluateJavascript(jsCode, null)
    }

    fun openChat() {
        webView.evaluateJavascript("javascript:if(window.Pylon) { window.Pylon('show'); }", null)
    }

    fun closeChat() {
        webView.evaluateJavascript("javascript:if(window.Pylon) { window.Pylon('hide'); }", null)
    }

    fun showChatBubble() {
        webView.evaluateJavascript("javascript:if(window.Pylon) { window.Pylon('showChatBubble'); }", null)
    }

    fun hideChatBubble() {
        webView.evaluateJavascript("javascript:if(window.Pylon) { window.Pylon('hideChatBubble'); }", null)
    }

    fun setNewIssueCustomFields(fields: Map<String, Any?>) {
        val json = fields.toJsonString()
        invokePylonCommand("setNewIssueCustomFields", json)
    }

    fun setTicketFormFields(fields: Map<String, Any?>) {
        val json = fields.toJsonString()
        invokePylonCommand("setTicketFormFields", json)
    }

    fun showNewMessage(message: String, isHtml: Boolean = false) {
        val messageArg = JSONObject.quote(message)
        if (isHtml) {
            invokePylonCommand("showNewMessage", messageArg, "{ isHtml: true }")
        } else {
            invokePylonCommand("showNewMessage", messageArg)
        }
    }

    fun showTicketForm(ticketFormSlug: String) {
        val slugArg = JSONObject.quote(ticketFormSlug)
        invokePylonCommand("showTicketForm", slugArg)
    }

    fun showKnowledgeBaseArticle(articleId: String) {
        val idArg = JSONObject.quote(articleId)
        invokePylonCommand("showKnowledgeBaseArticle", idArg)
    }

    fun updateEmailHash(emailHash: String?) {
        Pylon.setEmailHash(emailHash)
        initializeProbe()
    }

    fun updateUser(user: PylonUser) {
        Pylon.setUser(user)
        initializeProbe()
    }

    fun setListener(listener: PylonChatListener?) {
        this.listener = listener
    }

    fun setProbeListener(listener: PylonChatListener) {
        setListener(listener)
    }

    fun destroy() {
        activeFilePathCallback?.onReceiveValue(null)
        activeFilePathCallback = null
        listener = null
        webView.destroy()
    }

    private fun invokePylonCommand(command: String, vararg arguments: String) {
        val joinedArgs = arguments.joinToString(separator = ", ")
        val script = if (joinedArgs.isEmpty()) {
            "javascript:if(window.Pylon){ window.Pylon('$command'); }"
        } else {
            "javascript:if(window.Pylon){ window.Pylon('$command', $joinedArgs); }"
        }
        webView.evaluateJavascript(script, null)
    }

    private fun Map<String, Any?>.toJsonString(): String {
        val json = JSONObject()
        for ((key, value) in this) {
            if (value == null) {
                json.put(key, JSONObject.NULL)
            } else {
                json.put(key, value)
            }
        }
        return json.toString()
    }

    private fun generateHtml(config: PylonConfig, user: PylonUser?): String {
        val nonce = if (config.enableCSP) generateNonce(16) else ""

        val cspMeta = if (config.enableCSP) {
            val cspPolicy = """
                connect-src 'self' https://*.usepylon.com wss://*.pusher.com;
                script-src 'self' https://widget.usepylon.com 'nonce-$nonce';
                font-src 'self' https://*.usepylon.com;
                style-src 'self' https://*.usepylon.com 'nonce-$nonce' 'unsafe-inline';
                img-src 'self' https://*.usepylon.com https://pylon-avatars.s3.us-west-1.amazonaws.com https://d3vl36l12sfx26.cloudfront.net;
                frame-src *;
                child-src *;
                object-src 'none';
                base-uri 'self'
            """.trimIndent().replace("\n", " ")
            """<meta http-equiv="Content-Security-Policy" content="$cspPolicy">"""
        } else {
            ""
        }

        val nonceAttr = if (config.enableCSP) """nonce="$nonce"""" else ""

        val chatSettings = buildChatSettings(config, user)

        val primaryColorStyles = config.primaryColor?.let {
            """
                :root {
                    --pylon-primary-color: $it;
                }
            """.trimIndent()
        } ?: ""

        return """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
                $cspMeta
                <style $nonceAttr>
                    body {
                        margin: 0;
                        padding: 0;
                        padding-top: env(safe-area-inset-top);
                        padding-bottom: env(safe-area-inset-bottom);
                        padding-right: env(safe-area-inset-right);
                        padding-left: env(safe-area-inset-left);
                        background-color: transparent;
                        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                        pointer-events: none;
                    }
                    .pylon-widget, [id*="pylon"], [class*="pylon"] {
                        pointer-events: auto !important;
                    }
                    $primaryColorStyles
                </style>
            </head>
            <body>
                <script $nonceAttr>
                    if (!window.pylon) {
                        window.pylon = {};
                    }
                    window.pylon.chat_settings = $chatSettings;
                    console.log("Probe/Pylon initialized with:", window.pylon.chat_settings);
                </script>
                <script $nonceAttr>
                    (function(){
                        var e=window;
                        var t=document;
                        var n=function(){n.e(arguments)};
                        n.q=[];
                        n.e=function(e){n.q.push(e)};
                        e.Pylon=n;
                        var r=function(){
                            var e=t.createElement("script");
                            e.setAttribute("type","text/javascript");
                            e.setAttribute("async","true");
                            e.setAttribute("src","${config.widgetScriptUrl}");
                            var n=t.getElementsByTagName("script")[0];
                            n.parentNode.insertBefore(e,n)
                        };
                        if(t.readyState==="complete"){r()}
                        else if(e.addEventListener){e.addEventListener("load",r,false)}
                    })();
                </script>
                <script $nonceAttr>
                    window.probeReady = function() {
                        if (window.ProbeNative) {
                            window.ProbeNative.onReady();
                        }
                    };
                    if (window.Pylon) {
                        window.probeReady();
                    }
                </script>
            </body>
            </html>
        """.trimIndent()
    }

    private fun buildChatSettings(config: PylonConfig, user: PylonUser?): String {
        val fields = mutableListOf("app_id: '${config.appId}'")
        config.primaryColor?.let { fields += "primary_color: '$it'" }
        if (user != null) {
            fields += "email: '${user.email}'"
            fields += "name: '${user.name}'"
            user.avatarUrl?.let { fields += "avatar_url: '$it'" }
            user.emailHash?.let { fields += "email_hash: '$it'" }
            user.accountId?.let { fields += "account_id: '$it'" }
            user.accountExternalId?.let { fields += "account_external_id: '$it'" }
        }

        val joined = fields.joinToString(
            separator = ",\n                        ",
            prefix = "{\n                        ",
            postfix = "\n                    }"
        )
        return joined
    }

    private fun generateNonce(length: Int): String {
        val allowedChars = ('A'..'Z') + ('a'..'z') + ('0'..'9')
        return (1..length)
            .map { allowedChars.random() }
            .joinToString("")
    }

    inner class ProbeJSInterface {
        @JavascriptInterface
        fun log(value: String) {
            post { Log.d(TAG, value) }
        }

        @JavascriptInterface
        fun onInitialized() {
            post { listener?.onProbeInitialized() }
        }

        @JavascriptInterface
        fun onReady() {
            post { listener?.onProbeReady() }
        }

        @JavascriptInterface
        fun onChatWindowOpened() {
            post {
                isChatWindowOpen = true
                listener?.onChatOpened()
            }
        }

        @JavascriptInterface
        fun onChatWindowClosed() {
            post {
                isChatWindowOpen = false
                listener?.onChatClosed()
            }
        }

        @JavascriptInterface
        fun onInteractiveElementUpdate(selector: String) {
            post {
                log("Finding interactive bounds for: $selector")
                findInteractiveElementPosition(selector)
            }
        }

        @JavascriptInterface
        fun updateInteractiveBounds(selector: String, left: Float, top: Float, right: Float, bottom: Float) {
            post {
                log("Updating interactive bounds for: $selector ($left, $top) - ($right, $bottom)")
                interactiveBounds[selector]?.set(left.toInt(), top.toInt(), right.toInt(), bottom.toInt())
                if (Pylon.requireConfig().debugMode) {
                    debugOverlay.bounds = interactiveBounds
                }
            }
        }

        @JavascriptInterface
        fun onUnreadCountChanged(unreadCount: Double) {
            post {
                listener?.onUnreadCountChanged(unreadCount.toInt())
            }
        }
    }
}
