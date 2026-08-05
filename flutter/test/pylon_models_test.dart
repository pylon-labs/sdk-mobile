import 'package:flutter_test/flutter_test.dart';
import 'package:pylon_chat/pylon_chat.dart';

void main() {
  group('PylonConfig', () {
    // PylonChatView compares configs to decide whether to rebuild the web view,
    // so value equality here is load-bearing.
    test('two configs with the same values are equal', () {
      const PylonConfig a = PylonConfig(appId: 'app', primaryColor: '#5B4CF5');
      const PylonConfig b = PylonConfig(appId: 'app', primaryColor: '#5B4CF5');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('a changed field breaks equality', () {
      const PylonConfig a = PylonConfig(appId: 'app');
      expect(a, isNot(a.copyWith(appId: 'other')));
      expect(a, isNot(a.copyWith(debugMode: true)));
      expect(a, isNot(a.copyWith(widgetBaseUrl: 'https://example.com')));
    });

    test('serialises every field, leaving unset ones null', () {
      const PylonConfig config = PylonConfig(appId: 'app');
      expect(config.toMap(), <String, Object?>{
        'appId': 'app',
        'enableLogging': true,
        'primaryColor': null,
        'debugMode': false,
        'widgetBaseUrl': null,
        'widgetScriptUrl': null,
      });
    });
  });

  group('PylonUser', () {
    test('two users with the same values are equal', () {
      const PylonUser a = PylonUser(email: 'a@b.com', name: 'A');
      const PylonUser b = PylonUser(email: 'a@b.com', name: 'A');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('a late-arriving email hash breaks equality', () {
      const PylonUser user = PylonUser(email: 'a@b.com', name: 'A');
      expect(user, isNot(user.copyWith(emailHash: 'deadbeef')));
    });

    test('serialises every field', () {
      const PylonUser user = PylonUser(
        email: 'ada@example.com',
        name: 'Ada Lovelace',
        avatarUrl: 'https://example.com/a.png',
        emailHash: 'deadbeef',
        accountId: 'acct_1',
        accountExternalId: 'ext_1',
      );
      expect(user.toMap(), <String, Object?>{
        'email': 'ada@example.com',
        'name': 'Ada Lovelace',
        'avatarUrl': 'https://example.com/a.png',
        'emailHash': 'deadbeef',
        'accountId': 'acct_1',
        'accountExternalId': 'ext_1',
      });
    });

    test('toString does not leak the identity hash', () {
      const PylonUser user = PylonUser(
        email: 'ada@example.com',
        name: 'Ada',
        emailHash: 'deadbeef',
      );
      expect(user.toString(), isNot(contains('deadbeef')));
    });
  });
}
