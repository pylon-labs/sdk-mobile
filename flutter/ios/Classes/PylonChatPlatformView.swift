import Flutter
import UIKit

/// Hosts a `PylonChatView` inside Flutter and bridges it to Dart.
///
/// Method calls arrive from `PylonChatController`; widget events go back out on
/// the same channel, where `PylonChatView` turns them into callbacks and into
/// the hit test regions that let touches pass through to the Flutter app behind
/// the widget.
class PylonChatPlatformView: NSObject, FlutterPlatformView {

    private let channel: FlutterMethodChannel
    private let container: PylonChatContainerView

    /// Calls that arrived before the SDK view had been laid out into existence.
    private var pendingCalls: [(FlutterMethodCall, FlutterResult)] = []

    init(frame: CGRect,
         viewId: Int64,
         arguments: Any?,
         messenger: FlutterBinaryMessenger) {
        let params = arguments as? [String: Any] ?? [:]

        channel = FlutterMethodChannel(
            name: "\(PylonChatPlatformView.channelPrefix)\(viewId)",
            binaryMessenger: messenger
        )
        container = PylonChatContainerView(
            config: PylonChatPlatformView.parseConfig(params["config"]),
            user: PylonChatPlatformView.parseUser(params["user"]),
            frame: frame
        )

        super.init()

        container.listener = self
        container.onChatViewCreated = { [weak self] in
            self?.flushPendingCalls()
        }
        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
    }

    private func flushPendingCalls() {
        let queued = pendingCalls
        pendingCalls = []
        for (call, result) in queued {
            handle(call, result: result)
        }
    }

    func view() -> UIView {
        return container
    }

    deinit {
        channel.setMethodCallHandler(nil)
        // Anything still queued will never run; fail it rather than leaving the
        // Dart side awaiting a reply that cannot come.
        for (_, result) in pendingCalls {
            result(FlutterError(
                code: "disposed",
                message: "The Pylon chat widget was disposed.",
                details: nil
            ))
        }
        pendingCalls = []
        container.destroy()
    }

    // MARK: - Dart → native

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let chatView = container.chatView else {
            // The SDK view is built on the first layout pass with a real size, which
            // can land after the controller has already flushed its buffered calls.
            // Hold them until there is something to act on.
            pendingCalls.append((call, result))
            return
        }

        let args = call.arguments as? [String: Any] ?? [:]

        switch call.method {
        case "openChat":
            chatView.openChat()
        case "closeChat":
            chatView.closeChat()
        case "showChatBubble":
            chatView.showChatBubble()
        case "hideChatBubble":
            chatView.hideChatBubble()
        case "refreshInteractiveBounds":
            chatView.refreshInteractiveBounds()
        case "showNewMessage":
            chatView.showNewMessage(
                args["message"] as? String ?? "",
                isHtml: args["isHtml"] as? Bool ?? false
            )
        case "setNewIssueCustomFields":
            chatView.setNewIssueCustomFields(Self.fields(from: args["fields"]))
        case "setTicketFormFields":
            chatView.setTicketFormFields(Self.fields(from: args["fields"]))
        case "showTicketForm":
            chatView.showTicketForm(args["slug"] as? String ?? "")
        case "showKnowledgeBaseArticle":
            chatView.showKnowledgeBaseArticle(args["articleId"] as? String ?? "")
        case "updateUser":
            guard let user = Self.parseUser(args["user"]) else {
                result(FlutterError(
                    code: "invalid_user",
                    message: "A Pylon user needs both an email and a name.",
                    details: nil
                ))
                return
            }
            container.updateUser(user)
        case "updateEmailHash":
            guard let user = container.currentUser else {
                result(FlutterError(
                    code: "no_user",
                    message: "Set a user before setting an email hash.",
                    details: nil
                ))
                return
            }
            container.updateUser(PylonUser(
                email: user.email,
                name: user.name,
                avatarUrl: user.avatarUrl,
                emailHash: args["emailHash"] as? String,
                accountId: user.accountId,
                accountExternalId: user.accountExternalId
            ))
        default:
            result(FlutterMethodNotImplemented)
            return
        }

        result(nil)
    }

    // MARK: - Creation params

    private static func parseConfig(_ raw: Any?) -> PylonConfig {
        let map = raw as? [String: Any] ?? [:]
        return PylonConfig(
            appId: map["appId"] as? String ?? "",
            enableLogging: map["enableLogging"] as? Bool ?? true,
            primaryColor: map["primaryColor"] as? String,
            debugMode: map["debugMode"] as? Bool ?? false,
            widgetBaseUrl: map["widgetBaseUrl"] as? String,
            widgetScriptUrl: map["widgetScriptUrl"] as? String
        )
    }

    private static func parseUser(_ raw: Any?) -> PylonUser? {
        guard let map = raw as? [String: Any],
              let email = map["email"] as? String,
              let name = map["name"] as? String else {
            return nil
        }
        return PylonUser(
            email: email,
            name: name,
            avatarUrl: map["avatarUrl"] as? String,
            emailHash: map["emailHash"] as? String,
            accountId: map["accountId"] as? String,
            accountExternalId: map["accountExternalId"] as? String
        )
    }

    private static func fields(from raw: Any?) -> [String: Any] {
        guard let map = raw as? [String: Any] else { return [:] }
        return map.filter { !($0.value is NSNull) }
    }

    /// Must match `_PylonChatViewState._channelPrefix` on the Dart side.
    private static let channelPrefix = "com.pylon.chatwidget/pylon_chat_view_"
}

// MARK: - Native → Dart

extension PylonChatPlatformView: PylonChatListener {

    func onPylonLoaded() {
        channel.invokeMethod("onPylonLoaded", arguments: nil)
    }

    func onPylonInitialized() {
        channel.invokeMethod("onPylonInitialized", arguments: nil)
    }

    func onPylonReady() {
        channel.invokeMethod("onPylonReady", arguments: nil)
    }

    func onMessageReceived(message: String) {
        channel.invokeMethod("onMessageReceived", arguments: ["message": message])
    }

    func onChatOpened() {
        channel.invokeMethod("onChatOpened", arguments: nil)
    }

    func onChatClosed(wasOpen: Bool) {
        channel.invokeMethod("onChatClosed", arguments: ["wasOpen": wasOpen])
    }

    func onPylonError(error: String) {
        channel.invokeMethod("onPylonError", arguments: ["error": error])
    }

    func onUnreadCountChanged(count: Int) {
        channel.invokeMethod("onUnreadCountChanged", arguments: ["count": count])
    }

    func onInteractiveBoundsChanged(selector: String, bounds: CGRect) {
        // Points map 1:1 onto Flutter's logical pixels, so no scaling — but the
        // page's origin sits inside the view's by the web view's content inset,
        // and Flutter hit tests in view coordinates.
        let offset = container.contentOffset
        channel.invokeMethod("onInteractiveBoundsChanged", arguments: [
            "selector": selector,
            "left": bounds.minX + offset.x,
            "top": bounds.minY + offset.y,
            "right": bounds.maxX + offset.x,
            "bottom": bounds.maxY + offset.y
        ])
    }
}
