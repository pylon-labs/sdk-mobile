import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Renders the widget's unread count in the app's own chrome.
///
/// [PylonChatController.unreadCount] is a [ValueListenable], so a badge like
/// this needs no state of its own.
class UnreadBadge extends StatelessWidget {
  const UnreadBadge({super.key, required this.unreadCount});

  final ValueListenable<int> unreadCount;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: unreadCount,
      builder: (BuildContext context, int count, Widget? child) {
        return Badge(
          isLabelVisible: count > 0,
          label: Text('$count'),
          child: child,
        );
      },
      child: const Icon(Icons.forum_outlined),
    );
  }
}
