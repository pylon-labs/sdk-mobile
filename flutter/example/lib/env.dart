import 'package:pylon_chat/pylon_chat.dart';

/// Demo configuration, supplied at build time with `--dart-define`.
///
/// See `env.example` for the full list, or just run `./run.sh` after copying
/// `env.example` to `.env`.
abstract final class Env {
  /// Your Pylon app ID, from https://app.usepylon.com/settings.
  static const String appId = String.fromEnvironment('PYLON_APP_ID');

  /// Leave unset to use production (`widget.usepylon.com`).
  static const String widgetBaseUrl = String.fromEnvironment(
    'PYLON_WIDGET_BASE_URL',
  );

  static const String userEmail = String.fromEnvironment(
    'PYLON_USER_EMAIL',
    defaultValue: 'demo@example.com',
  );

  static const String userName = String.fromEnvironment(
    'PYLON_USER_NAME',
    defaultValue: 'Demo User',
  );

  static const String userEmailHash = String.fromEnvironment(
    'PYLON_USER_EMAIL_HASH',
  );

  static const bool enableLogging = bool.fromEnvironment(
    'PYLON_ENABLE_LOGGING',
    defaultValue: true,
  );

  /// Draws the SDK's hit test regions over the widget.
  static const bool debugMode = bool.fromEnvironment('PYLON_DEBUG_MODE');

  /// Whether an app ID was supplied. Without one there is nothing to load.
  static bool get isConfigured => appId.isNotEmpty;

  static PylonConfig get config => PylonConfig(
    appId: appId,
    enableLogging: enableLogging,
    debugMode: debugMode,
    widgetBaseUrl: widgetBaseUrl.isEmpty ? null : widgetBaseUrl,
  );

  static PylonUser get user => PylonUser(
    email: userEmail,
    name: userName,
    emailHash: userEmailHash.isEmpty ? null : userEmailHash,
  );
}
