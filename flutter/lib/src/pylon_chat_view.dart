import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'pylon_chat_controller.dart';
import 'pylon_config.dart';
import 'pylon_interactive_region.dart';
import 'pylon_user.dart';

/// The Pylon chat widget.
///
/// This is an overlay: it expands to fill whatever space it is given, but only
/// the chat bubble (and any popup survey or message) is actually painted.
/// Pointers that land anywhere else pass straight through to the widgets behind
/// it, so the usual way to add it is as the last child of a full-screen [Stack]:
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
///
/// To place it above every route, put that [Stack] in [WidgetsApp.builder] —
/// see the README for the full pattern.
///
/// Changing [config], or switching to a user with a different email, rebuilds
/// the underlying web view from scratch. Other changes to [user] are applied in
/// place.
class PylonChatView extends StatefulWidget {
  /// Creates a Pylon chat widget.
  const PylonChatView({
    super.key,
    required this.config,
    this.user,
    this.controller,
    this.passthroughTouches = true,
    this.onLoaded,
    this.onInitialized,
    this.onReady,
    this.onChatOpened,
    this.onChatClosed,
    this.onUnreadCountChanged,
    this.onMessageReceived,
    this.onError,
  });

  /// Configuration for the widget. Requires at least an app ID.
  final PylonConfig config;

  /// The visitor to identify conversations with.
  ///
  /// When null the widget runs anonymously and collects an email in the chat.
  final PylonUser? user;

  /// Drives the widget imperatively — opening the chat, pre-filling a message,
  /// and so on. Optional; the widget works on its own.
  final PylonChatController? controller;

  /// Whether pointers outside the widget's interactive elements fall through to
  /// the widgets behind this one.
  ///
  /// Leave this on. Turning it off makes the whole overlay opaque to pointers,
  /// which blocks your entire app while the bubble is visible; it exists for
  /// the case where the widget is given a small box of its own rather than
  /// being laid over the app.
  final bool passthroughTouches;

  /// Called when the web view hosting the widget finishes loading.
  final VoidCallback? onLoaded;

  /// Called when the widget has been initialised with the config and user.
  final VoidCallback? onInitialized;

  /// Called when the widget's own scripts report that they are ready.
  final VoidCallback? onReady;

  /// Called when the chat window expands.
  final VoidCallback? onChatOpened;

  /// Called when the chat window collapses. `wasOpen` is whether it had been
  /// open — a close can be reported for an already-closed window.
  final void Function(bool wasOpen)? onChatClosed;

  /// Called when the number of unread messages changes.
  final void Function(int count)? onUnreadCountChanged;

  /// Called when a message arrives.
  final void Function(String message)? onMessageReceived;

  /// Called when the widget fails to load.
  final void Function(String error)? onError;

  @override
  State<PylonChatView> createState() => _PylonChatViewState();
}

class _PylonChatViewState extends State<PylonChatView> {
  static const String _viewType = 'com.pylon.chatwidget/pylon_chat_view';
  static const String _channelPrefix = 'com.pylon.chatwidget/pylon_chat_view_';

  /// The platform view claims a pointer as soon as it gets one. By the time a
  /// pointer reaches it, [PylonInteractiveRegion] has already decided the
  /// pointer landed on the widget rather than on the app behind it, so there is
  /// nothing left to arbitrate.
  static final Set<Factory<OneSequenceGestureRecognizer>> _gestureRecognizers =
      <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
      };

  MethodChannel? _channel;

  /// Latest reported bounds per element, in logical pixels relative to this
  /// widget. Zero-sized rects mean the element is currently hidden.
  final Map<String, Rect> _interactiveBounds = <String, Rect>{};

  List<Rect> _regions = const <Rect>[];
  bool _isChatOpen = false;

  /// Bumped to force the platform view to be torn down and rebuilt.
  int _viewRevision = 0;

  Size? _lastSize;
  final List<Timer> _refreshTimers = <Timer>[];

  /// The widget reports where its elements are when it shows or hides them, but
  /// not when they move for some other reason — the web view's viewport
  /// changing, or the bubble's own entrance animation still running. Both
  /// leave the bounds pointing at where the bubble *was*, which would make it
  /// untappable. So after anything that can move it, re-measure: once promptly,
  /// and once more after an animation has had time to settle.
  static const List<Duration> _refreshDelays = <Duration>[
    Duration(milliseconds: 150),
    Duration(milliseconds: 800),
  ];

  @override
  void didUpdateWidget(PylonChatView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      final MethodChannel? channel = _channel;
      if (channel != null) {
        final PylonChatController? old = oldWidget.controller;
        if (old != null) detachPylonController(old, channel);
        final PylonChatController? current = widget.controller;
        if (current != null) attachPylonController(current, channel);
      }
    }

    // A different app ID or widget URL means a different web view; a different
    // person means a conversation that must not inherit the previous session.
    final bool identityChanged = widget.user?.email != oldWidget.user?.email;
    if (widget.config != oldWidget.config || identityChanged) {
      _recreatePlatformView();
      return;
    }

    final PylonUser? user = widget.user;
    if (user != null && user != oldWidget.user) {
      _channel?.invokeMethod<void>('updateUser', <String, Object?>{
        'user': user.toMap(),
      });
    }
  }

  @override
  void dispose() {
    _cancelBoundsRefresh();
    _releaseChannel();
    super.dispose();
  }

  void _scheduleBoundsRefresh() {
    _cancelBoundsRefresh();
    for (final Duration delay in _refreshDelays) {
      _refreshTimers.add(
        Timer(delay, () {
          // Fire and forget: the view may have gone away, and a missed refresh
          // is corrected by the next one.
          _channel
              ?.invokeMethod<void>('refreshInteractiveBounds')
              .catchError((Object _) {});
        }),
      );
    }
  }

  void _cancelBoundsRefresh() {
    for (final Timer timer in _refreshTimers) {
      timer.cancel();
    }
    _refreshTimers.clear();
  }

  /// Called during layout. A resize moves the widget's elements without the
  /// widget saying so, so the bounds have to be re-measured.
  void _handleSize(Size size) {
    if (_lastSize == size) return;
    final bool isResize = _lastSize != null;
    _lastSize = size;
    if (isResize) _scheduleBoundsRefresh();
  }

  void _recreatePlatformView() {
    _releaseChannel();
    setState(() {
      _viewRevision++;
      _interactiveBounds.clear();
      _regions = const <Rect>[];
      _isChatOpen = false;
    });
  }

  void _releaseChannel() {
    final MethodChannel? channel = _channel;
    if (channel == null) return;
    channel.setMethodCallHandler(null);
    final PylonChatController? controller = widget.controller;
    if (controller != null) detachPylonController(controller, channel);
    _channel = null;
  }

  void _onPlatformViewCreated(int id) {
    final MethodChannel channel = MethodChannel('$_channelPrefix$id');
    channel.setMethodCallHandler(_handlePlatformCall);
    _channel = channel;
    final PylonChatController? controller = widget.controller;
    if (controller != null) attachPylonController(controller, channel);
  }

  Future<void> _handlePlatformCall(MethodCall call) async {
    if (!mounted) return;
    final Map<Object?, Object?>? args =
        call.arguments as Map<Object?, Object?>?;

    switch (call.method) {
      case 'onPylonLoaded':
        _scheduleBoundsRefresh();
        widget.onLoaded?.call();
      case 'onPylonInitialized':
        widget.onInitialized?.call();
      case 'onPylonReady':
        _scheduleBoundsRefresh();
        widget.onReady?.call();
      case 'onChatOpened':
        _setChatOpen(true);
        widget.onChatOpened?.call();
      case 'onChatClosed':
        final bool wasOpen = args?['wasOpen'] as bool? ?? _isChatOpen;
        _setChatOpen(false);
        // The bubble comes back as the window collapses; catch where it lands.
        _scheduleBoundsRefresh();
        widget.onChatClosed?.call(wasOpen);
      case 'onUnreadCountChanged':
        final int count = (args?['count'] as num?)?.toInt() ?? 0;
        final PylonChatController? controller = widget.controller;
        if (controller != null) setPylonUnreadCount(controller, count);
        widget.onUnreadCountChanged?.call(count);
      case 'onMessageReceived':
        widget.onMessageReceived?.call(args?['message'] as String? ?? '');
      case 'onPylonError':
        widget.onError?.call(args?['error'] as String? ?? 'Unknown error');
      case 'onInteractiveBoundsChanged':
        _updateInteractiveBounds(args);
    }
  }

  void _setChatOpen(bool isOpen) {
    final PylonChatController? controller = widget.controller;
    if (controller != null) setPylonChatOpen(controller, isOpen);
    if (_isChatOpen == isOpen) return;
    setState(() => _isChatOpen = isOpen);
  }

  void _updateInteractiveBounds(Map<Object?, Object?>? args) {
    if (args == null) return;
    final String? selector = args['selector'] as String?;
    if (selector == null) return;

    final Rect bounds = Rect.fromLTRB(
      (args['left'] as num?)?.toDouble() ?? 0,
      (args['top'] as num?)?.toDouble() ?? 0,
      (args['right'] as num?)?.toDouble() ?? 0,
      (args['bottom'] as num?)?.toDouble() ?? 0,
    );
    if (_interactiveBounds[selector] == bounds) return;
    _interactiveBounds[selector] = bounds;

    setState(() {
      _regions = <Rect>[
        for (final Rect rect in _interactiveBounds.values)
          if (!rect.isEmpty) rect,
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        _handleSize(constraints.biggest);
        final Widget view = _buildPlatformView(context);
        if (!widget.passthroughTouches) return view;
        return PylonInteractiveRegion(
          regions: _regions,
          absorbAll: _isChatOpen,
          child: view,
        );
      },
    );
  }

  Widget _buildPlatformView(BuildContext context) {
    final Map<String, Object?> creationParams = <String, Object?>{
      'config': widget.config.toMap(),
      'user': widget.user?.toMap(),
    };
    final TextDirection direction =
        Directionality.maybeOf(context) ?? TextDirection.ltr;
    final Key key = ValueKey<int>(_viewRevision);

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Hybrid composition: the chat is a web view with text input, and the
        // keyboard and text selection controls only behave correctly when the
        // real Android view is in the hierarchy.
        return PlatformViewLink(
          key: key,
          viewType: _viewType,
          surfaceFactory: (BuildContext context, PlatformViewController controller) {
            return AndroidViewSurface(
              controller: controller as AndroidViewController,
              hitTestBehavior: PlatformViewHitTestBehavior.opaque,
              gestureRecognizers: _gestureRecognizers,
            );
          },
          onCreatePlatformView: (PlatformViewCreationParams params) {
            final AndroidViewController controller =
                PlatformViewsService.initExpensiveAndroidView(
                  id: params.id,
                  viewType: _viewType,
                  layoutDirection: direction,
                  creationParams: creationParams,
                  creationParamsCodec: const StandardMessageCodec(),
                  onFocus: () => params.onFocusChanged(true),
                );
            controller
              ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
              ..addOnPlatformViewCreatedListener(_onPlatformViewCreated)
              ..create();
            return controller;
          },
        );
      case TargetPlatform.iOS:
        return UiKitView(
          key: key,
          viewType: _viewType,
          layoutDirection: direction,
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          gestureRecognizers: _gestureRecognizers,
        );
      // Pylon's mobile SDKs cover Android and iOS only.
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return const SizedBox.shrink();
    }
  }
}
