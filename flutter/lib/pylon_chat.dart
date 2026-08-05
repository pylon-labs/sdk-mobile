/// Pylon's chat widget for Flutter apps.
///
/// Drop a [PylonChatView] over your app and your users can talk to support
/// without leaving it:
///
/// ```dart
/// Stack(
///   children: <Widget>[
///     MyApp(),
///     PylonChatView(
///       config: PylonConfig(appId: 'YOUR_APP_ID'),
///       user: PylonUser(email: 'user@example.com', name: 'Ada Lovelace'),
///     ),
///   ],
/// )
/// ```
library;

export 'src/pylon_chat_controller.dart' show PylonChatController;
export 'src/pylon_chat_view.dart' show PylonChatView;
export 'src/pylon_config.dart' show PylonConfig;
export 'src/pylon_user.dart' show PylonUser;
