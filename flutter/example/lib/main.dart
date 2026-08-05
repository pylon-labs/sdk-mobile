import 'package:flutter/material.dart';
import 'package:pylon_chat/pylon_chat.dart';

import 'env.dart';
import 'event_log.dart';
import 'pages/home_page.dart';
import 'pages/second_page.dart';
import 'pages/setup_page.dart';

void main() {
  runApp(const DemoApp());
}

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  final PylonChatController _controller = PylonChatController();
  final EventLog _events = EventLog();

  /// Null while "signed out", to show the widget running anonymously.
  PylonUser? _user = Env.user;

  @override
  void dispose() {
    _controller.dispose();
    _events.dispose();
    super.dispose();
  }

  void _setUser(PylonUser? user) {
    setState(() => _user = user);
    _events.add(user == null ? 'signed out' : 'signed in as ${user.email}');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pylon Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B4CF5)),
      ),
      routes: <String, WidgetBuilder>{
        SecondPage.route: (_) => const SecondPage(),
      },
      home: Env.isConfigured
          ? HomePage(
              controller: _controller,
              events: _events,
              user: _user,
              onUserChanged: _setUser,
            )
          : const SetupPage(),
      builder: (BuildContext context, Widget? child) {
        if (!Env.isConfigured) return child ?? const SizedBox.shrink();
        return Stack(
          children: <Widget>[
            if (child != null) child,
            // Above the Navigator, so the bubble survives route changes and is
            // not squeezed by a Scaffold resizing for the keyboard. The widget
            // only takes the touches that land on it — everything else reaches
            // the app underneath.
            Positioned.fill(
              child: PylonChatView(
                // Switching user recreates the web view, so the next
                // conversation does not inherit the previous session.
                key: ValueKey<String?>(_user?.email),
                config: Env.config,
                user: _user,
                controller: _controller,
                onLoaded: () => _events.add('loaded'),
                onReady: () => _events.add('ready'),
                onChatOpened: () => _events.add('chat opened'),
                onChatClosed: (bool wasOpen) =>
                    _events.add('chat closed (wasOpen: $wasOpen)'),
                onUnreadCountChanged: (int count) =>
                    _events.add('unread: $count'),
                onMessageReceived: (String message) =>
                    _events.add('message: $message'),
                onError: (String error) => _events.add('error: $error'),
              ),
            ),
          ],
        );
      },
    );
  }
}
