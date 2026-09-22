import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const _keyToken = 'access_token';
  static const _keyCachedUser = 'cached_user_json';

  Future<void> saveToken(String token) =>
      _storage.write(key: _keyToken, value: token);

  Future<String?> getToken() => _storage.read(key: _keyToken);

  Future<void> deleteToken() => _storage.delete(key: _keyToken);

  Future<bool> hasToken() async => (await _storage.read(key: _keyToken)) != null;

  Future<void> saveUserJson(String json) =>
      _storage.write(key: _keyCachedUser, value: json);

  Future<String?> getCachedUserJson() =>
      _storage.read(key: _keyCachedUser);

  Future<void> deleteUserJson() =>
      _storage.delete(key: _keyCachedUser);

  Future<void> deleteAll() => _storage.deleteAll();
}
