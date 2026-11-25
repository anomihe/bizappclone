import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the login token (and last email for "Welcome back").
abstract class TokenStore {
  Future<String?> readToken();
  Future<String?> readEmail();
  Future<void> save({required String token, required String email});
  Future<void> clearToken();
  Future<void> clearAll();
}

/// Keychain (iOS) / Keystore-backed storage (Android).
class SecureTokenStore implements TokenStore {
  static const _tokenKey = 'bizpaddi_api_token';
  static const _emailKey = 'bizpaddi_last_email';
  final FlutterSecureStorage _storage;

  SecureTokenStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  @override
  Future<String?> readToken() => _storage.read(key: _tokenKey);
  @override
  Future<String?> readEmail() => _storage.read(key: _emailKey);

  @override
  Future<void> save({required String token, required String email}) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _emailKey, value: email);
  }

  /// Signs out but keeps the email so "Welcome back" can greet the user.
  @override
  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  @override
  Future<void> clearAll() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _emailKey);
  }
}

/// For tests.
class MemoryTokenStore implements TokenStore {
  String? token;
  String? email;
  @override
  Future<String?> readToken() async => token;
  @override
  Future<String?> readEmail() async => email;
  @override
  Future<void> save({required String token, required String email}) async {
    this.token = token;
    this.email = email;
  }

  @override
  Future<void> clearToken() async => token = null;
  @override
  Future<void> clearAll() async => token = email = null;
}
