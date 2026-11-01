import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StoredSession {
  const StoredSession({required this.cookies, required this.signedIn, this.profilePath});

  final Map<String, String> cookies;
  final bool signedIn;
  final String? profilePath;
}

abstract class SessionStore {
  Future<StoredSession?> read();

  Future<void> write(StoredSession session);

  Future<void> clear();
}

class MemorySessionStore implements SessionStore {
  StoredSession? session;

  @override
  Future<void> clear() async => session = null;

  @override
  Future<StoredSession?> read() async => session;

  @override
  Future<void> write(StoredSession session) async => this.session = session;
}

class SecureSessionStore implements SessionStore {
  SecureSessionStore({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'nini.session';
  final FlutterSecureStorage _storage;

  @override
  Future<void> clear() => _storage.delete(key: _key);

  @override
  Future<StoredSession?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    final cookies = <String, String>{};
    final stored = decoded['cookies'];
    if (stored is Map) {
      stored.forEach((key, value) {
        if (key != null && value != null) cookies['$key'] = '$value';
      });
    }
    final path = decoded['profilePath'];
    return StoredSession(
      cookies: cookies,
      signedIn: decoded['signedIn'] == true,
      profilePath: path is String && path.isNotEmpty ? path : null,
    );
  }

  @override
  Future<void> write(StoredSession session) {
    return _storage.write(
      key: _key,
      value: jsonEncode({
        'cookies': session.cookies,
        'signedIn': session.signedIn,
        'profilePath': session.profilePath,
      }),
    );
  }
}
