# Changelog

## 0.1.0

Initial release.

- `PylonChatView`, an overlay widget that hosts the native chat widget on iOS
  and Android.
- `PylonChatController` for opening and closing the chat, driving the bubble,
  pre-filling messages, opening ticket forms and knowledge base articles, and
  setting custom fields. Calls made before the widget mounts are buffered.
- `unreadCount` and `isChatOpen` as `ValueListenable`s, for badges and other
  app chrome.
- Touch pass-through: pointers that miss the widget's interactive elements
  continue to the Flutter widgets behind it.
- Android file attachments, wired through the plugin's activity result
  listener.
