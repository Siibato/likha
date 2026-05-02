import 'dart:convert';
import 'dart:math';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class EncryptionService {
  String encryptField(String? plaintext);
  String? decryptField(String? ciphertext);
}

class AesEncryptionService implements EncryptionService {
  static const _keyStorageKey = 'db_encryption_key';

  late final Key _key;
  late final IV _iv;
  late final Encrypter _encrypter;

  AesEncryptionService._(String base64Key) {
    _key = Key.fromBase64(base64Key);
    _iv = IV.fromLength(16);
    _encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
  }

  static Future<AesEncryptionService> create(FlutterSecureStorage storage) async {
    String? existingKey = await storage.read(key: _keyStorageKey);
    if (existingKey == null) {
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
      existingKey = base64Encode(keyBytes);
      await storage.write(key: _keyStorageKey, value: existingKey);
    }
    return AesEncryptionService._(existingKey);
  }

  @override
  String encryptField(String? plaintext) {
    if (plaintext == null || plaintext.isEmpty) return plaintext ?? '';
    final encrypted = _encrypter.encrypt(plaintext, iv: _iv);
    return encrypted.base64;
  }

  @override
  String? decryptField(String? ciphertext) {
    if (ciphertext == null || ciphertext.isEmpty) return ciphertext;
    try {
      return _encrypter.decrypt64(ciphertext, iv: _iv);
    } catch (_) {
      return ciphertext;
    }
  }
}
