import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'pylon_user.dart';

/// Drives a [PylonChatView] imperatively.
///
/// Create one, hand it to the widget, and call methods on it:
///
/// ```dart
/// final controller = PylonChatController();
/// ...
/// PylonChatView(config: config, controller: controller);
/// ...
/// controller.openChat();
/// ```
///
/// Calls made before the widget has mounted are buffered and replayed once the
/// platform view exists, so there is no need to wait for a "ready" callback.
///
/// Dispose the controller with your [State] to release its listenables.
class PylonChatController {
  /// Creates a controller. Attach it to a `PylonChatView` to make it live.
  PylonChatController();

  MethodChannel? _channel;
  final List<_PendingCall> _pending = <_PendingCall>[];
  bool _disposed = false;

  final ValueNotifier<int> _unreadCount = ValueNotifier<int>(0);
  final ValueNotifier<bool> _isChatOpen = ValueNotifier<bool>(false);

  /// The number of unread messages, as reported by the widget.
  ///
  /// Useful for driving your own badge:
  ///
  /// ```dart
  /// ValueListenableBuilder<int>(
  ///   valueListenable: controller.unreadCount,
  ///   builder: (context, count, _) => Badge(count: count),
  /// )
  /// ```
  ValueListenable<int> get unreadCount => _unreadCount;

  /// Whether the chat window is currently expanded.
  ValueListenable<bool> get isChatOpen => _isChatOpen;

  /// Whether a [PylonChatView] is currently backing this controller.
  ///
  /// Calls made while this is `false` are buffered, not dropped.
  bool get isAttached => _channel != null;

  /// Expands the chat window.
  Future<void> openChat() => _invoke('openChat');

  /// Collapses the chat window back to the bubble.
  Future<void> closeChat() => _invoke('closeChat');

  /// Shows the chat bubble.
  Future<void> showChatBubble() => _invoke('showChatBubble');

  /// Hides the chat bubble.
  ///
  /// The chat window can still be opened with [openChat] while hidden, which is
  /// how you back a support entry point of your own design.
  Future<void> hideChatBubble() => _invoke('hideChatBubble');

  /// Opens the chat window with [message] pre-filled in the composer.
  ///
  /// Set [isHtml] to interpret [message] as HTML rather than plain text.
  Future<void> showNewMessage(String message, {bool isHtml = false}) {
    return _invoke('showNewMessage', <String, Object?>{
      'message': message,
      'isHtml': isHtml,
    });
  }

  /// Sets custom fields applied to issues created from this session.
  ///
  /// Values must be primitives (`String`, `num`, `bool`). Null values are
  /// dropped rather than sent, so omitting a key and passing null for it mean
  /// the same thing.
  Future<void> setNewIssueCustomFields(Map<String, Object?> fields) {
    return _invoke('setNewIssueCustomFields', <String, Object?>{
      'fields': _withoutNulls(fields),
    });
  }

  /// Pre-fills fields on the ticket form.
  ///
  /// Values follow the same rules as [setNewIssueCustomFields].
  Future<void> setTicketFormFields(Map<String, Object?> fields) {
    return _invoke('setTicketFormFields', <String, Object?>{
      'fields': _withoutNulls(fields),
    });
  }

  static Map<String, Object> _withoutNulls(Map<String, Object?> fields) {
    return <String, Object>{
      for (final MapEntry<String, Object?> entry in fields.entries)
        if (entry.value != null) entry.key: entry.value!,
    };
  }

  /// Opens the ticket form identified by [slug].
  Future<void> showTicketForm(String slug) {
    return _invoke('showTicketForm', <String, Object?>{'slug': slug});
  }

  /// Opens the knowledge base article identified by [articleId].
  Future<void> showKnowledgeBaseArticle(String articleId) {
    return _invoke('showKnowledgeBaseArticle', <String, Object?>{
      'articleId': articleId,
    });
  }

  /// Replaces the identified user.
  ///
  /// Prefer passing a new `user` to [PylonChatView] — this exists for cases
  /// where you hold the controller but not the widget. Switching to a
  /// *different* person (log out, log in) should recreate the widget with a new
  /// `key` instead, so the previous session's conversation is not reused.
  Future<void> updateUser(PylonUser user) {
    return _invoke('updateUser', <String, Object?>{'user': user.toMap()});
  }

  /// Updates the identity verification hash for the current user.
  Future<void> setEmailHash(String? emailHash) {
    return _invoke('updateEmailHash', <String, Object?>{
      'emailHash': emailHash,
    });
  }

  /// Re-queries the widget for the position of its interactive elements.
  ///
  /// The SDK does this automatically whenever the widget reports a change. Call
  /// it manually only if a tap target has visibly moved without a taps landing
  /// — for example after an unusual layout change.
  Future<void> refreshInteractiveBounds() => _invoke('refreshInteractiveBounds');

  /// Releases the controller's listenables.
  ///
  /// After this the controller is dead: further calls throw.
  void dispose() {
    _disposed = true;
    _channel = null;
    for (final _PendingCall call in _pending) {
      call.completer.complete();
    }
    _pending.clear();
    _unreadCount.dispose();
    _isChatOpen.dispose();
  }

  Future<void> _invoke(String method, [Map<String, Object?>? arguments]) {
    if (_disposed) {
      throw StateError(
        'PylonChatController.$method called after dispose(). Create a new '
        'controller instead of reusing a disposed one.',
      );
    }
    final MethodChannel? channel = _channel;
    if (channel != null) {
      return channel.invokeMethod<void>(method, arguments);
    }
    // No platform view yet — buffer until one attaches.
    final Completer<void> completer = Completer<void>();
    _pending.add(
      _PendingCall(method: method, arguments: arguments, completer: completer),
    );
    return completer.future;
  }

  void _attach(MethodChannel channel) {
    _channel = channel;
    if (_pending.isEmpty) return;
    final List<_PendingCall> queued = List<_PendingCall>.of(_pending);
    _pending.clear();
    for (final _PendingCall call in queued) {
      call.completer.complete(
        channel.invokeMethod<void>(call.method, call.arguments),
      );
    }
  }

  void _detach(MethodChannel channel) {
    if (identical(_channel, channel)) _channel = null;
  }
}

class _PendingCall {
  _PendingCall({
    required this.method,
    required this.arguments,
    required this.completer,
  });

  final String method;
  final Map<String, Object?>? arguments;
  final Completer<void> completer;
}

/// Binds [controller] to the platform view's [channel]. Called by
/// `PylonChatView` when its platform view is created.
@internal
void attachPylonController(
  PylonChatController controller,
  MethodChannel channel,
) => controller._attach(channel);

/// Unbinds [controller] from [channel], if it is still the active one.
@internal
void detachPylonController(
  PylonChatController controller,
  MethodChannel channel,
) => controller._detach(channel);

/// Publishes an unread count from the platform to [controller].
@internal
void setPylonUnreadCount(PylonChatController controller, int count) =>
    controller._unreadCount.value = count;

/// Publishes the open/closed state from the platform to [controller].
@internal
void setPylonChatOpen(PylonChatController controller, bool isOpen) =>
    controller._isChatOpen.value = isOpen;
