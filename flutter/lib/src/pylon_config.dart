import 'package:flutter/foundation.dart';

/// Configuration for the Pylon chat widget.
///
/// At minimum you need an [appId], which you can find under
/// Settings → Chat Widget in [app.usepylon.com](https://app.usepylon.com).
@immutable
class PylonConfig {
  /// Creates a configuration for the Pylon chat widget.
  const PylonConfig({
    required this.appId,
    this.enableLogging = true,
    this.primaryColor,
    this.debugMode = false,
    this.widgetBaseUrl,
    this.widgetScriptUrl,
  });

  /// The host the chat widget is served from when [widgetBaseUrl] is omitted.
  static const String defaultWidgetBaseUrl = 'https://widget.usepylon.com';

  /// Your Pylon app ID.
  final String appId;

  /// Whether the SDK writes its own diagnostics (and the widget's console
  /// output) to the platform log.
  final bool enableLogging;

  /// Overrides the widget's primary colour, as a CSS colour string.
  final String? primaryColor;

  /// Draws an overlay on top of the interactive regions the SDK tracks.
  ///
  /// Useful when a tap on the chat bubble is not registering: the overlay shows
  /// exactly which areas the SDK considers tappable.
  final bool debugMode;

  /// Overrides the host the widget is loaded from.
  ///
  /// Defaults to [defaultWidgetBaseUrl].
  final String? widgetBaseUrl;

  /// Overrides the URL of the widget script.
  ///
  /// Defaults to `<widgetBaseUrl>/widget/<appId>`.
  final String? widgetScriptUrl;

  /// Returns a copy of this config with the given fields replaced.
  PylonConfig copyWith({
    String? appId,
    bool? enableLogging,
    String? primaryColor,
    bool? debugMode,
    String? widgetBaseUrl,
    String? widgetScriptUrl,
  }) {
    return PylonConfig(
      appId: appId ?? this.appId,
      enableLogging: enableLogging ?? this.enableLogging,
      primaryColor: primaryColor ?? this.primaryColor,
      debugMode: debugMode ?? this.debugMode,
      widgetBaseUrl: widgetBaseUrl ?? this.widgetBaseUrl,
      widgetScriptUrl: widgetScriptUrl ?? this.widgetScriptUrl,
    );
  }

  /// Serialises this config for the platform channel.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'appId': appId,
      'enableLogging': enableLogging,
      'primaryColor': primaryColor,
      'debugMode': debugMode,
      'widgetBaseUrl': widgetBaseUrl,
      'widgetScriptUrl': widgetScriptUrl,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PylonConfig &&
        other.appId == appId &&
        other.enableLogging == enableLogging &&
        other.primaryColor == primaryColor &&
        other.debugMode == debugMode &&
        other.widgetBaseUrl == widgetBaseUrl &&
        other.widgetScriptUrl == widgetScriptUrl;
  }

  @override
  int get hashCode => Object.hash(
    appId,
    enableLogging,
    primaryColor,
    debugMode,
    widgetBaseUrl,
    widgetScriptUrl,
  );

  @override
  String toString() => 'PylonConfig(appId: $appId)';
}
