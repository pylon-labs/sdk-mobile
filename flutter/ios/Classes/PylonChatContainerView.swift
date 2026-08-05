import Foundation
import UIKit
import WebKit

/// Holds the SDK's `PylonChatView` and defers creating it until it has a size.
///
/// Flutter creates platform views before it knows how big they are. The chat
/// widget needs a real viewport — a zero-sized web view reports zero-sized
/// elements, and the bounds it reports are what makes the bubble tappable — so
/// the view is built on the first layout pass that has non-zero bounds.
final class PylonChatContainerView: UIView {

    private let config: PylonConfig
    private var user: PylonUser?

    /// The SDK view, once it has been created.
    private(set) var chatView: PylonChatView?

    /// Forwarded to the SDK view when it is created.
    weak var listener: PylonChatListener? {
        didSet { chatView?.listener = listener }
    }

    /// Called once, right after the SDK view is created.
    var onChatViewCreated: (() -> Void)?

    init(config: PylonConfig, user: PylonUser?, frame: CGRect) {
        self.config = config
        self.user = user
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        createChatViewIfNeeded()
    }

    /// Replaces the identified user on the live view.
    func updateUser(_ user: PylonUser) {
        self.user = user
        chatView?.updateUser(user)
    }

    /// The user the widget is currently identified as.
    var currentUser: PylonUser? { user }

    func destroy() {
        listener = nil
        chatView?.listener = nil
        chatView?.destroy()
        chatView?.removeFromSuperview()
        chatView = nil
    }

    private func createChatViewIfNeeded() {
        guard chatView == nil, bounds.width > 0, bounds.height > 0 else { return }

        let view = PylonChatView(config: config, user: user)
        defer { onChatViewCreated?() }
        view.listener = listener
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor),
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        chatView = view
    }

    /// The SDK's web view, once the SDK view has been created.
    private var webView: WKWebView? {
        return chatView?.subviews.compactMap { $0 as? WKWebView }.first
    }

    /// How far the web view's content is inset from this view's top-left.
    ///
    /// WKWebView adjusts its content for the safe area, so the page is laid out
    /// below and inside the view's own origin. That makes the coordinates the
    /// page reports — which is what the SDK measures its elements in — differ
    /// from the view coordinates Flutter hit tests in, by exactly this much.
    var contentOffset: CGPoint {
        guard let inset = webView?.scrollView.adjustedContentInset else {
            return .zero
        }
        return CGPoint(x: inset.left, y: inset.top)
    }

    /// Hand the touch straight to the web view.
    ///
    /// Flutter has already hit tested it against the widget's interactive
    /// regions before forwarding it here, and Flutter's hit test is the one that
    /// decides whether the app behind gets the touch instead. Letting the SDK
    /// view filter it a second time — against bounds in the page's coordinate
    /// space rather than this view's — would only reject touches Flutter has
    /// already accepted.
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let webView = webView else { return nil }
        return webView.hitTest(convert(point, to: webView), with: event)
    }
}
