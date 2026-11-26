import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the login token (and last email for "Welcome back").
abstract class TokenStore {
  Future<String?> readToken();
  Future<String?> readEmail();

  /// `admin` (business owner), `team` (staff) or `client` (customer).
  Future<String?> readRole();
  Future<void> save({required String token, required String email, String role = 'admin'});
  Future<void> clearToken();
  Future<void> clearAll();
}

/// Keychain (iOS) / Keystore-backed storage (Android).
class SecureTokenStore implements TokenStore {
  static const _tokenKey = 'bizpaddi_api_token';
  static const _emailKey = 'bizpaddi_last_email';
  static const _roleKey = 'bizpaddi_account_role';
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
  Future<String?> readRole() => _storage.read(key: _roleKey);
  @override
  Future<void> save({required String token, required String email, String role = 'admin'}) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _roleKey, value: role);
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
  String? role;
  @override
  Future<String?> readToken() async => token;
  @override
  Future<String?> readRole() async => role;
  @override
  Future<String?> readEmail() async => email;
  @override
  Future<void> save({required String token, required String email, String role = 'admin'}) async {
    this.token = token;
    this.email = email;
    this.role = role;
  }

  @override
  Future<void> clearToken() async => token = null;
  @override
  Future<void> clearAll() async => token = email = null;
}
