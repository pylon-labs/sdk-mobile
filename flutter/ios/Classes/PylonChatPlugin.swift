import Flutter
import UIKit

/// Registers the Pylon chat widget as a Flutter platform view.
public class PylonChatPlugin: NSObject, FlutterPlugin {

    /// Must match `_PylonChatViewState._viewType` on the Dart side.
    static let viewType = "com.pylon.chatwidget/pylon_chat_view"

    public static func register(with registrar: FlutterPluginRegistrar) {
        let factory = PylonChatViewFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: viewType)
    }
}

/// Creates a `PylonChatPlatformView` for each `PylonChatView` widget.
class PylonChatViewFactory: NSObject, FlutterPlatformViewFactory {

    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(withFrame frame: CGRect,
                viewIdentifier viewId: Int64,
                arguments args: Any?) -> FlutterPlatformView {
        return PylonChatPlatformView(
            frame: frame,
            viewId: viewId,
            arguments: args,
            messenger: messenger
        )
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}
