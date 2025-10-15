//
//  ChatWidgetIOS.swift
//  ChatWidgetIOS
//
//  Created by Ben Soh on 10/7/25.
//

import Foundation
import UIKit
import WebKit

// MARK: - PylonConfig

public struct PylonConfig {
    public let appId: String
    public let enableLogging: Bool
    public let enableCSP: Bool
    public let primaryColor: String?
    public let debugMode: Bool
    public let widgetBaseUrl: String
    public let widgetScriptUrl: String

    private static let defaultWidgetBaseUrl = "https://widget.usepylon.com"

    public init(appId: String,
                enableLogging: Bool = true,
                enableCSP: Bool = false,
                primaryColor: String? = nil,
                debugMode: Bool = false,
                widgetBaseUrl: String? = nil,
                widgetScriptUrl: String? = nil) {
        self.appId = appId
        self.enableLogging = enableLogging
        self.enableCSP = enableCSP
        self.primaryColor = primaryColor
        self.debugMode = debugMode
        self.widgetBaseUrl = widgetBaseUrl ?? Self.defaultWidgetBaseUrl
        self.widgetScriptUrl = widgetScriptUrl ?? "\(Self.defaultWidgetBaseUrl)/widget/\(appId)"
    }
}

// MARK: - PylonUser

public struct PylonUser {
    public let email: String
    public let name: String
    public let avatarUrl: String?
    public let emailHash: String?
    public let accountId: String?
    public let accountExternalId: String?

    public init(email: String,
                name: String,
                avatarUrl: String? = nil,
                emailHash: String? = nil,
                accountId: String? = nil,
                accountExternalId: String? = nil) {
        self.email = email
        self.name = name
        self.avatarUrl = avatarUrl
        self.emailHash = emailHash
        self.accountId = accountId
        self.accountExternalId = accountExternalId
    }
}

// MARK: - PylonChatListener

public protocol PylonChatListener: AnyObject {
    func onPylonLoaded()
    func onPylonInitialized()
    func onPylonReady()
    func onMessageReceived(message: String)
    func onChatOpened()
    func onChatClosed()
    func onPylonError(error: String)
    func onUnreadCountChanged(count: Int)
}

public extension PylonChatListener {
    func onPylonLoaded() {}
    func onPylonInitialized() {}
    func onPylonReady() {}
    func onMessageReceived(message: String) {}
    func onChatOpened() {}
    func onChatClosed() {}
    func onPylonError(error: String) {}
    func onUnreadCountChanged(count: Int) {}
}

// MARK: - Pylon (Main SDK Entry Point)

public class Pylon {
    public static let shared = Pylon()

    private var config: PylonConfig?
    private var user: PylonUser?

    private init() {}

    public func initialize(config: PylonConfig) {
        self.config = config
    }

    public func initialize(appId: String,
                          enableLogging: Bool = true,
                          enableCSP: Bool = false,
                          primaryColor: String? = nil,
                          debugMode: Bool = false,
                          widgetBaseUrl: String? = nil,
                          widgetScriptUrl: String? = nil) {
        let config = PylonConfig(
            appId: appId,
            enableLogging: enableLogging,
            enableCSP: enableCSP,
            primaryColor: primaryColor,
            debugMode: debugMode,
            widgetBaseUrl: widgetBaseUrl,
            widgetScriptUrl: widgetScriptUrl
        )
        self.config = config
    }

    public func setUser(_ user: PylonUser) {
        self.user = user
    }

    public func setUser(email: String, name: String,
                       avatarUrl: String? = nil,
                       emailHash: String? = nil,
                       accountId: String? = nil,
                       accountExternalId: String? = nil) {
        self.user = PylonUser(
            email: email,
            name: name,
            avatarUrl: avatarUrl,
            emailHash: emailHash,
            accountId: accountId,
            accountExternalId: accountExternalId
        )
    }

    public func clearUser() {
        self.user = nil
    }

    public func setEmailHash(_ emailHash: String?) {
        guard var user = self.user else {
            print("⚠️ Set user before calling setEmailHash()")
            return
        }
        self.user = PylonUser(
            email: user.email,
            name: user.name,
            avatarUrl: user.avatarUrl,
            emailHash: emailHash,
            accountId: user.accountId,
            accountExternalId: user.accountExternalId
        )
    }

    public func createChat() -> PylonChatView {
        guard let config = config else {
            fatalError("Pylon SDK not initialized. Call Pylon.shared.initialize() first.")
        }
        return PylonChatView(config: config, user: user)
    }

    internal func requireConfig() -> PylonConfig {
        guard let config = config else {
            fatalError("Pylon SDK not initialized. Call Pylon.shared.initialize() first.")
        }
        return config
    }

    internal func currentUser() -> PylonUser? {
        return user
    }
}

// MARK: - PylonChatView

public class PylonChatView: UIView {
    private let config: PylonConfig
    private var user: PylonUser?
    private var webView: WKWebView!
    private var hasStartedLoading = false
    private var isLoaded = false
    private var isChatWindowOpen = false

    public weak var listener: PylonChatListener?

    // Interactive element IDs to track
    private enum InteractiveElementId: String {
        case fab = "pylon-chat-bubble"
        case survey = "pylon-chat-popup-survey"
        case message = "pylon-chat-popup-message"
    }

    // Track bounds of interactive elements
    private var interactiveBounds: [String: CGRect] = [
        InteractiveElementId.fab.rawValue: .zero,
        InteractiveElementId.survey.rawValue: .zero,
        InteractiveElementId.message.rawValue: .zero
    ]

    init(config: PylonConfig, user: PylonUser?) {
        self.config = config
        self.user = user
        super.init(frame: .zero)
        setupWebView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var debugOverlay: DebugOverlayView = {
        let overlay = DebugOverlayView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.isUserInteractionEnabled = false
        overlay.backgroundColor = .clear
        return overlay
    }()

    private func setupWebView() {
        NSLog("🚀 PylonChatView: setupWebView called")

        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let userContentController = WKUserContentController()

        // Add message handler for JavaScript bridge
        userContentController.add(WeakScriptMessageHandler(delegate: self), name: "PylonNative")
        configuration.userContentController = userContentController

        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.backgroundColor = .clear
        webView.navigationDelegate = self
        webView.uiDelegate = self

        // Make webView not block touches when chat is closed
        webView.isUserInteractionEnabled = true

        addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Add debug overlay if in debug mode
        if config.debugMode {
            addSubview(debugOverlay)
            NSLayoutConstraint.activate([
                debugOverlay.topAnchor.constraint(equalTo: topAnchor),
                debugOverlay.leadingAnchor.constraint(equalTo: leadingAnchor),
                debugOverlay.trailingAnchor.constraint(equalTo: trailingAnchor),
                debugOverlay.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }

        NSLog("🚀 PylonChatView: setupWebView completed")
    }

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        NSLog("🔍 PylonChatView.hitTest - point: (\(point.x), \(point.y)), isChatWindowOpen: \(isChatWindowOpen)")

        // If chat window is open, pass all touches to webView
        if isChatWindowOpen {
            NSLog("✅ Chat is OPEN - passing touches to webView")
            return webView.hitTest(point, with: event)
        }

        // If chat window is closed, check if touch is within interactive bounds
        let shouldHandleTap = interactiveBounds.values.contains { bounds in
            !bounds.isEmpty && bounds.contains(point)
        }

        if shouldHandleTap {
            NSLog("✅ Touch is within interactive bounds - passing to webView")
            return webView.hitTest(point, with: event)
        }

        // Let touches fall through to views behind this view
        NSLog("❌ Touch outside interactive area - passing through")
        return nil
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            ensurePylonLoaded()
        }
    }

    public func ensurePylonLoaded(forceReload: Bool = false) {
        if forceReload {
            hasStartedLoading = false
            isLoaded = false
        }

        guard !hasStartedLoading else { return }

        let html = generateHTML()
        hasStartedLoading = true
        webView.loadHTMLString(html, baseURL: URL(string: config.widgetBaseUrl))
    }

    private func generateHTML() -> String {
        let chatSettings = buildChatSettings()

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                body {
                    margin: 0;
                    padding: 0;
                    background-color: transparent;
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    pointer-events: none;
                }
                .pylon-widget, [id*="pylon"], [class*="pylon"] {
                    pointer-events: auto !important;
                }
            </style>
        </head>
        <body>
            <script>
                if (!window.pylon) {
                    window.pylon = {};
                }
                window.pylon.chat_settings = \(chatSettings);
                console.log("Pylon initialized with:", window.pylon.chat_settings);
            </script>
            <script>
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
                        e.setAttribute("src","\(config.widgetScriptUrl)");
                        var n=t.getElementsByTagName("script")[0];
                        n.parentNode.insertBefore(e,n)
                    };
                    if(t.readyState==="complete"){r()}
                    else if(e.addEventListener){e.addEventListener("load",r,false)}
                })();
            </script>
            <script>
                window.pylonReady = function() {
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.PylonNative) {
                        window.webkit.messageHandlers.PylonNative.postMessage({type: 'onReady'});
                    }
                };
                if (window.Pylon) {
                    window.pylonReady();
                }
            </script>
        </body>
        </html>
        """
    }

    private func buildChatSettings() -> String {
        var fields: [String] = ["app_id: '\(config.appId)'"]

        if let primaryColor = config.primaryColor {
            fields.append("primary_color: '\(primaryColor)'")
        }

        if let user = user {
            fields.append("email: '\(user.email)'")
            fields.append("name: '\(user.name)'")
            if let avatarUrl = user.avatarUrl {
                fields.append("avatar_url: '\(avatarUrl)'")
            }
            if let emailHash = user.emailHash {
                fields.append("email_hash: '\(emailHash)'")
            }
            if let accountId = user.accountId {
                fields.append("account_id: '\(accountId)'")
            }
            if let accountExternalId = user.accountExternalId {
                fields.append("account_external_id: '\(accountExternalId)'")
            }
        }

        return "{\n            " + fields.joined(separator: ",\n            ") + "\n        }"
    }

    private func initializePylon() {
        let js = """
        (function() {
            if (window.Pylon) {
                window.Pylon('onShow', function() {
                    window.webkit.messageHandlers.PylonNative.postMessage({type: 'onChatWindowOpened'});
                });

                window.Pylon('onHide', function() {
                    window.webkit.messageHandlers.PylonNative.postMessage({type: 'onChatWindowClosed'});
                });

                window.Pylon('onShowChatBubble', function() {
                    window.webkit.messageHandlers.PylonNative.postMessage({type: 'onInteractiveElementUpdate', selector: '\(InteractiveElementId.fab.rawValue)'});
                    window.webkit.messageHandlers.PylonNative.postMessage({type: 'onInteractiveElementUpdate', selector: '\(InteractiveElementId.message.rawValue)'});
                });

                window.Pylon('onHideChatBubble', function() {
                    window.webkit.messageHandlers.PylonNative.postMessage({type: 'onInteractiveElementUpdate', selector: '\(InteractiveElementId.fab.rawValue)'});
                    window.webkit.messageHandlers.PylonNative.postMessage({type: 'onInteractiveElementUpdate', selector: '\(InteractiveElementId.message.rawValue)'});
                });

                window.Pylon('onPopupSurveyVisibilityChange', function(isShowing) {
                    window.webkit.messageHandlers.PylonNative.postMessage({type: 'onInteractiveElementUpdate', selector: '\(InteractiveElementId.survey.rawValue)'});
                });

                window.Pylon('onPopupMessageVisibilityChange', function(isShowing) {
                    window.webkit.messageHandlers.PylonNative.postMessage({type: 'onInteractiveElementUpdate', selector: '\(InteractiveElementId.message.rawValue)'});
                });

                window.Pylon('onChangeUnreadMessagesCount', function(unreadCount) {
                    window.webkit.messageHandlers.PylonNative.postMessage({type: 'onUnreadCountChanged', count: unreadCount});
                });
            }

            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.PylonNative) {
                window.webkit.messageHandlers.PylonNative.postMessage({type: 'onInitialized'});
            }

            console.log('Pylon initialized with settings:', window.pylon.chat_settings);
        })();
        """

        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    private func findInteractiveElementPosition(selector: String) {
        let js = """
        (function() {
            var element = document.querySelector('[id="\(selector)"]');
            var rect = element ? element.getBoundingClientRect() : null;

            if (rect !== null && rect.width > 0) {
                window.webkit.messageHandlers.PylonNative.postMessage({
                    type: 'updateInteractiveBounds',
                    selector: '\(selector)',
                    left: rect.left,
                    top: rect.top,
                    right: rect.right,
                    bottom: rect.bottom
                });
            } else {
                window.webkit.messageHandlers.PylonNative.postMessage({
                    type: 'updateInteractiveBounds',
                    selector: '\(selector)',
                    left: 0,
                    top: 0,
                    right: 0,
                    bottom: 0
                });
            }
        })();
        """

        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    // MARK: - Public API

    public func openChat() {
        NSLog("📱 Pylon API: openChat() called")
        executeJavaScript("if(window.Pylon) { window.Pylon('show'); }")
    }

    public func closeChat() {
        NSLog("📱 Pylon API: closeChat() called")
        executeJavaScript("if(window.Pylon) { window.Pylon('hide'); }")
    }

    public func showChatBubble() {
        NSLog("📱 Pylon API: showChatBubble() called")
        executeJavaScript("if(window.Pylon) { window.Pylon('showChatBubble'); }")
    }

    public func hideChatBubble() {
        NSLog("📱 Pylon API: hideChatBubble() called")
        executeJavaScript("if(window.Pylon) { window.Pylon('hideChatBubble'); }")
    }

    public func setNewIssueCustomFields(_ fields: [String: Any]) {
        let jsObject = buildJavaScriptObject(from: fields)
        NSLog("📱 Pylon API: setNewIssueCustomFields with object: \(jsObject)")
        invokePylonCommand("setNewIssueCustomFields", arguments: [jsObject], isJsonObject: true)
    }

    public func setTicketFormFields(_ fields: [String: Any]) {
        let jsObject = buildJavaScriptObject(from: fields)
        NSLog("📱 Pylon API: setTicketFormFields with object: \(jsObject)")
        invokePylonCommand("setTicketFormFields", arguments: [jsObject], isJsonObject: true)
    }

    private func buildJavaScriptObject(from dict: [String: Any]) -> String {
        let pairs = dict.map { key, value -> String in
            let jsValue: String
            if let stringValue = value as? String {
                // Escape single quotes and newlines in strings
                let escaped = stringValue
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "'", with: "\\'")
                    .replacingOccurrences(of: "\n", with: "\\n")
                    .replacingOccurrences(of: "\r", with: "\\r")
                jsValue = "'\(escaped)'"
            } else if let boolValue = value as? Bool {
                jsValue = boolValue ? "true" : "false"
            } else if let numberValue = value as? NSNumber {
                jsValue = "\(numberValue)"
            } else {
                // Fallback for other types
                jsValue = "'\(value)'"
            }
            return "\(key): \(jsValue)"
        }
        return "{ " + pairs.joined(separator: ", ") + " }"
    }

    public func showNewMessage(_ message: String, isHtml: Bool = false) {
        let escapedMessage = message.replacingOccurrences(of: "'", with: "\\'")
                                   .replacingOccurrences(of: "\n", with: "\\n")
        if isHtml {
            invokePylonCommand("showNewMessage", arguments: ["'\(escapedMessage)'", "{ isHtml: true }"])
        } else {
            invokePylonCommand("showNewMessage", arguments: ["'\(escapedMessage)'"])
        }
    }

    public func showTicketForm(_ ticketFormSlug: String) {
        invokePylonCommand("showTicketForm", arguments: ["'\(ticketFormSlug)'"])
    }

    public func showKnowledgeBaseArticle(_ articleId: String) {
        invokePylonCommand("showKnowledgeBaseArticle", arguments: ["'\(articleId)'"])
    }

    public func updateEmailHash(_ emailHash: String?) {
        Pylon.shared.setEmailHash(emailHash)
        initializePylon()
    }

    public func updateUser(_ user: PylonUser) {
        Pylon.shared.setUser(user)
        self.user = user
        initializePylon()
    }

    public func destroy() {
        listener = nil
        webView.stopLoading()
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "PylonNative")
    }

    // MARK: - Private Helpers

    private func executeJavaScript(_ script: String) {
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    private func invokePylonCommand(_ command: String, arguments: [String] = [], isJsonObject: Bool = false) {
        let script: String
        if arguments.isEmpty {
            script = "if(window.Pylon){ window.Pylon('\(command)'); }"
        } else {
            // If isJsonObject is true, don't quote the arguments (they're already JSON strings)
            let formattedArgs = arguments.joined(separator: ", ")
            script = "if(window.Pylon){ window.Pylon('\(command)', \(formattedArgs)); }"
        }
        NSLog("📱 Executing JS: \(script)")
        executeJavaScript(script)
    }
}

// MARK: - WKNavigationDelegate

extension PylonChatView: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if !isLoaded {
            isLoaded = true
            initializePylon()
            listener?.onPylonLoaded()
        }
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        listener?.onPylonError(error: error.localizedDescription)
    }
}

// MARK: - WKUIDelegate

extension PylonChatView: WKUIDelegate {
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Handle window.open() and target="_blank" links
        if let url = navigationAction.request.url {
            NSLog("📱 Opening external URL: \(url)")
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        return nil
    }
}

// MARK: - WKScriptMessageHandler

extension PylonChatView: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
              let type = body["type"] as? String else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            switch type {
            case "onInitialized":
                NSLog("📱 Pylon: onInitialized")
                self?.listener?.onPylonInitialized()
            case "onReady":
                NSLog("📱 Pylon: onReady")
                self?.listener?.onPylonReady()
            case "onChatWindowOpened":
                NSLog("📱 Pylon: Chat Window OPENED ✅")
                self?.isChatWindowOpen = true
                self?.listener?.onChatOpened()
            case "onChatWindowClosed":
                NSLog("📱 Pylon: Chat Window CLOSED ❌")
                self?.isChatWindowOpen = false
                self?.listener?.onChatClosed()
            case "onUnreadCountChanged":
                if let count = body["count"] as? Int {
                    NSLog("📱 Pylon: Unread count changed to \(count)")
                    self?.listener?.onUnreadCountChanged(count: count)
                }
            case "onInteractiveElementUpdate":
                if let selector = body["selector"] as? String {
                    NSLog("📱 Pylon: Interactive element update for \(selector)")
                    self?.findInteractiveElementPosition(selector: selector)
                }
            case "updateInteractiveBounds":
                if let selector = body["selector"] as? String,
                   let left = body["left"] as? CGFloat,
                   let top = body["top"] as? CGFloat,
                   let right = body["right"] as? CGFloat,
                   let bottom = body["bottom"] as? CGFloat {
                    let rect = CGRect(x: left, y: top, width: right - left, height: bottom - top)
                    NSLog("📱 Pylon: Updating bounds for \(selector): \(rect)")
                    self?.interactiveBounds[selector] = rect

                    // Update debug overlay
                    if let config = self?.config, config.debugMode {
                        self?.debugOverlay.interactiveBounds = self?.interactiveBounds ?? [:]
                    }
                }
            default:
                NSLog("📱 Pylon: Unknown message type: \(type)")
                break
            }
        }
    }
}

// MARK: - SwiftUI Wrapper

import SwiftUI

public struct PylonChatHostView: UIViewRepresentable {
    @Binding public var chatView: PylonChatView?
    @Binding public var unreadCount: Int

    public init(chatView: Binding<PylonChatView?>, unreadCount: Binding<Int>) {
        self._chatView = chatView
        self._unreadCount = unreadCount
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(unreadCount: $unreadCount)
    }

    public func makeUIView(context: Context) -> PylonChatView {
        let chatView = Pylon.shared.createChat()
        chatView.listener = context.coordinator

        DispatchQueue.main.async {
            self.chatView = chatView
        }

        return chatView
    }

    public func updateUIView(_ uiView: PylonChatView, context: Context) {
        // No updates needed
    }

    public static func dismantleUIView(_ uiView: PylonChatView, coordinator: Coordinator) {
        uiView.destroy()
    }

    public class Coordinator: PylonChatListener {
        @Binding var unreadCount: Int

        init(unreadCount: Binding<Int>) {
            _unreadCount = unreadCount
        }

        public func onUnreadCountChanged(count: Int) {
            unreadCount = count
        }
    }
}

// MARK: - Weak Script Message Handler Wrapper

private class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?

    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}

// MARK: - Debug Overlay View

private class DebugOverlayView: UIView {
    var interactiveBounds: [String: CGRect] = [:] {
        didSet {
            setNeedsDisplay()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else { return }

        for (selector, rect) in interactiveBounds {
            guard !rect.isEmpty else { continue }

            let color = getColor(for: selector)

            // Draw filled rectangle with transparency
            context.setFillColor(color.withAlphaComponent(0.3).cgColor)
            context.fill(rect)

            // Draw border
            context.setStrokeColor(color.cgColor)
            context.setLineWidth(4)
            context.stroke(rect)

            // Draw label
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .bold),
                .foregroundColor: color,
                .strokeColor: UIColor.black,
                .strokeWidth: -2.0
            ]

            let labelText = selector as NSString
            let labelPoint = CGPoint(x: rect.origin.x + 5, y: max(rect.origin.y - 20, 5))
            labelText.draw(at: labelPoint, withAttributes: attributes)
        }
    }

    private func getColor(for selector: String) -> UIColor {
        // Generate consistent color from string hash
        let hash = abs(selector.hashValue)

        // Use HSB to ensure colors are vibrant and distinct
        let hue = CGFloat((hash & 0xFFFF) % 360) / 360.0
        let saturation = 0.7 + CGFloat((hash >> 16) & 0xFF) / 255.0 * 0.3
        let brightness = 0.8 + CGFloat((hash >> 24) & 0xFF) / 255.0 * 0.2

        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
    }
}
