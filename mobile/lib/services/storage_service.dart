import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences? _webPrefs;

  StorageService(this._secureStorage, [this._webPrefs]);

  // Storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userRoleKey = 'user_role';

  // Access Token
  Future<void> saveAccessToken(String token) async {
    await _write(_accessTokenKey, token);
  }

  Future<String?> getAccessToken() async {
    return _read(_accessTokenKey);
  }

  // Refresh Token
  Future<void> saveRefreshToken(String token) async {
    await _write(_refreshTokenKey, token);
  }

  Future<String?> getRefreshToken() async {
    return _read(_refreshTokenKey);
  }

  // User ID
  Future<void> saveUserId(String userId) async {
    await _write(_userIdKey, userId);
  }

  Future<String?> getUserId() async {
    return _read(_userIdKey);
  }

  // User Role
  Future<void> saveUserRole(String role) async {
    await _write(_userRoleKey, role);
  }

  Future<String?> getUserRole() async {
    return _read(_userRoleKey);
  }

  Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
      saveUserId(userId),
    ]);
  }

  Future<void> clearAuthData() async {
    await Future.wait([
      _delete(_accessTokenKey),
      _delete(_refreshTokenKey),
      _delete(_userIdKey),
      _delete(_userRoleKey),
    ]);
  }

  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // Platform-aware storage helpers.
  // Web: uses SharedPreferences (plain localStorage, no Web Crypto).
  // Mobile/desktop: uses FlutterSecureStorage (OS keychain/keystore).

  Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      await _webPrefs!.setString(key, value);
    } else {
      await _secureStorage.write(key: key, value: value);
    }
  }

  Future<String?> _read(String key) async {
    if (kIsWeb) {
      return _webPrefs!.getString(key);
    } else {
      return await _secureStorage.read(key: key);
    }
  }

  Future<void> _delete(String key) async {
    if (kIsWeb) {
      await _webPrefs!.remove(key);
    } else {
      await _secureStorage.delete(key: key);
    }
  }
}
