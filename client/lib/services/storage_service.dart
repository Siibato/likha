import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;

  StorageService(this._secureStorage, this._prefs);

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
  // Mobile/desktop: prefers FlutterSecureStorage, falls back to SharedPreferences
  // if the OS keychain/keystore is unavailable (common in macOS debug builds).

  Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      await _prefs.setString(key, value);
      return;
    }
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (_) {
      // Secure storage failed — fall back to prefs.
      await _prefs.setString(key, value);
    }
  }

  Future<String?> _read(String key) async {
    if (kIsWeb) {
      return _prefs.getString(key);
    }
    try {
      final value = await _secureStorage.read(key: key);
      if (value != null) return value;
    } catch (_) {
      // Secure storage failed — fall through to prefs.
    }
    return _prefs.getString(key);
  }

  Future<void> _delete(String key) async {
    if (kIsWeb) {
      await _prefs.remove(key);
      return;
    }
    try {
      await _secureStorage.delete(key: key);
    } catch (_) {
      // Secure storage failed — still clear prefs below.
    }
    await _prefs.remove(key);
  }
}
