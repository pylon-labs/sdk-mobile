import 'package:flutter/foundation.dart';

/// The visitor the chat widget identifies conversations with.
///
/// Pass `null` for the user to run the widget anonymously — Pylon will ask for
/// an email in the chat itself.
@immutable
class PylonUser {
  /// Creates a Pylon user.
  const PylonUser({
    required this.email,
    required this.name,
    this.avatarUrl,
    this.emailHash,
    this.accountId,
    this.accountExternalId,
  });

  /// The user's email address.
  final String email;

  /// The user's display name.
  final String name;

  /// URL of the user's avatar image.
  final String? avatarUrl;

  /// HMAC-SHA256 of [email], for
  /// [identity verification](https://docs.usepylon.com/pylon-docs/chat-widget/identity-verification).
  ///
  /// Generate this on your server — never in the app, since shipping the
  /// signing secret to a mobile binary defeats the point of verifying.
  final String? emailHash;

  /// The Pylon account ID this user belongs to.
  final String? accountId;

  /// The ID of this user's account in your own system.
  final String? accountExternalId;

  /// Returns a copy of this user with the given fields replaced.
  PylonUser copyWith({
    String? email,
    String? name,
    String? avatarUrl,
    String? emailHash,
    String? accountId,
    String? accountExternalId,
  }) {
    return PylonUser(
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      emailHash: emailHash ?? this.emailHash,
      accountId: accountId ?? this.accountId,
      accountExternalId: accountExternalId ?? this.accountExternalId,
    );
  }

  /// Serialises this user for the platform channel.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'email': email,
      'name': name,
      'avatarUrl': avatarUrl,
      'emailHash': emailHash,
      'accountId': accountId,
      'accountExternalId': accountExternalId,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PylonUser &&
        other.email == email &&
        other.name == name &&
        other.avatarUrl == avatarUrl &&
        other.emailHash == emailHash &&
        other.accountId == accountId &&
        other.accountExternalId == accountExternalId;
  }

  @override
  int get hashCode => Object.hash(
    email,
    name,
    avatarUrl,
    emailHash,
    accountId,
    accountExternalId,
  );

  @override
  String toString() => 'PylonUser(email: $email, name: $name)';
}
