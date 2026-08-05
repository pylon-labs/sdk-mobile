import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pylon_chat/pylon_chat.dart';
import 'package:pylon_chat/src/pylon_chat_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannel channel;
  late List<MethodCall> calls;

  setUp(() {
    calls = <MethodCall>[];
    channel = const MethodChannel('com.pylon.chatwidget/pylon_chat_view_0');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('forwards calls once attached', () async {
    final PylonChatController controller = PylonChatController();
    attachPylonController(controller, channel);

    await controller.openChat();
    await controller.showNewMessage('hello', isHtml: true);

    expect(calls.map((MethodCall c) => c.method), <String>[
      'openChat',
      'showNewMessage',
    ]);
    expect(calls.last.arguments, <String, Object?>{
      'message': 'hello',
      'isHtml': true,
    });
    controller.dispose();
  });

  test('buffers calls made before the widget mounts', () async {
    final PylonChatController controller = PylonChatController();
    expect(controller.isAttached, isFalse);

    // Nothing to send to yet — these must not be lost.
    final Future<void> pending = Future.wait(<Future<void>>[
      controller.hideChatBubble(),
      controller.openChat(),
    ]);
    expect(calls, isEmpty);

    attachPylonController(controller, channel);
    await pending;

    expect(controller.isAttached, isTrue);
    expect(calls.map((MethodCall c) => c.method), <String>[
      'hideChatBubble',
      'openChat',
    ]);
    controller.dispose();
  });

  test('drops null custom field values rather than sending them', () async {
    final PylonChatController controller = PylonChatController();
    attachPylonController(controller, channel);

    await controller.setNewIssueCustomFields(<String, Object?>{
      'source': 'flutter',
      'tier': null,
      'seats': 12,
    });

    expect(calls.single.arguments, <String, Object?>{
      'fields': <String, Object?>{'source': 'flutter', 'seats': 12},
    });
    controller.dispose();
  });

  test('publishes unread count and open state to listeners', () {
    final PylonChatController controller = PylonChatController();
    final List<int> counts = <int>[];
    final List<bool> open = <bool>[];
    controller.unreadCount.addListener(() => counts.add(controller.unreadCount.value));
    controller.isChatOpen.addListener(() => open.add(controller.isChatOpen.value));

    expect(controller.unreadCount.value, 0);
    expect(controller.isChatOpen.value, isFalse);

    setPylonUnreadCount(controller, 3);
    setPylonChatOpen(controller, true);

    expect(counts, <int>[3]);
    expect(open, <bool>[true]);
    controller.dispose();
  });

  test('detaching stops forwarding and re-buffers', () async {
    final PylonChatController controller = PylonChatController();
    attachPylonController(controller, channel);
    await controller.openChat();
    expect(calls, hasLength(1));

    detachPylonController(controller, channel);
    expect(controller.isAttached, isFalse);

    unawaited(controller.closeChat());
    expect(calls, hasLength(1), reason: 'buffered, not sent');

    attachPylonController(controller, channel);
    await Future<void>.delayed(Duration.zero);
    expect(calls.map((MethodCall c) => c.method), <String>[
      'openChat',
      'closeChat',
    ]);
    controller.dispose();
  });

  test('a disposed controller refuses further calls', () {
    final PylonChatController controller = PylonChatController();
    controller.dispose();
    expect(controller.openChat, throwsStateError);
  });

  test('user updates carry every field', () async {
    final PylonChatController controller = PylonChatController();
    attachPylonController(controller, channel);

    await controller.updateUser(
      const PylonUser(
        email: 'ada@example.com',
        name: 'Ada Lovelace',
        accountId: 'acct_1',
      ),
    );

    expect(calls.single.method, 'updateUser');
    final Map<Object?, Object?> user =
        (calls.single.arguments as Map<Object?, Object?>)['user']!
            as Map<Object?, Object?>;
    expect(user['email'], 'ada@example.com');
    expect(user['name'], 'Ada Lovelace');
    expect(user['accountId'], 'acct_1');
    expect(user['emailHash'], isNull);
    controller.dispose();
  });
}
