import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:likha/domain/setup/entities/school_config.dart';

class SetupCryptoException implements Exception {
  final String message;
  const SetupCryptoException(this.message);

  @override
  String toString() => 'SetupCryptoException: $message';
}

/// Pure stateless utility for school setup encryption/decryption.
///
/// SETUP_SECRET is baked into the APK at compile time via --dart-define.
/// Both QR payloads and short codes are encrypted with the same secret,
/// ensuring the server URL is never exposed as plain text.
class SetupCrypto {
  SetupCrypto._();

  static const String _rawSecret = String.fromEnvironment(
    'SETUP_SECRET',
    defaultValue: '',
  );

  /// Pads or truncates the secret to exactly 32 bytes for AES-256.
  static String get _paddedSecret {
    if (_rawSecret.isEmpty) {
      throw const SetupCryptoException(
        'SETUP_SECRET is not set. Build with --dart-define=SETUP_SECRET=...',
      );
    }
    final bytes = utf8.encode(_rawSecret);
    if (bytes.length >= 32) return utf8.decode(bytes.sublist(0, 32));
    return _rawSecret.padRight(32, '0');
  }

  static enc.Encrypter get _encrypter =>
      enc.Encrypter(enc.AES(enc.Key.fromUtf8(_paddedSecret), mode: enc.AESMode.cbc));

  /// Fixed IV derived from first 16 bytes of secret (deterministic for short codes).
  static enc.IV get _iv {
    final bytes = Uint8List.fromList(utf8.encode(_paddedSecret).sublist(0, 16));
    return enc.IV(bytes);
  }

  // ---------------------------------------------------------------------------
  // QR payload
  // ---------------------------------------------------------------------------

  /// Encrypts a JSON payload to a Base64 string for embedding in a QR code.
  /// Format: Base64(IV[16] + ciphertext)
  static String encryptPayload(String json) {
    final iv = enc.IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(json, iv: iv);
    final combined = Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
    return base64.encode(combined);
  }

  /// Decrypts a Base64-encoded QR payload and returns a [SchoolConfig].
  /// Throws [SetupCryptoException] on invalid payload or decryption failure.
  static SchoolConfig decryptQrPayload(String base64Payload) {
    try {
      final combined = base64.decode(base64Payload);
      if (combined.length < 17) {
        throw const SetupCryptoException('Payload too short');
      }
      final iv = enc.IV(Uint8List.fromList(combined.sublist(0, 16)));
      final cipherBytes = Uint8List.fromList(combined.sublist(16));
      final encrypted = enc.Encrypted(cipherBytes);
      final json = _encrypter.decrypt(encrypted, iv: iv);
      final map = jsonDecode(json) as Map<String, dynamic>;
      final url = map['url'] as String?;
      final name = map['name'] as String?;
      if (url == null || name == null) {
        throw const SetupCryptoException('Missing url or name in payload');
      }
      return SchoolConfig(serverUrl: url, schoolName: name);
    } on SetupCryptoException {
      rethrow;
    } catch (e) {
      throw SetupCryptoException('Failed to decrypt payload: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Short code (6-char Base36)
  // ---------------------------------------------------------------------------

  /// Derives a deterministic 6-character Base36 short code from a JSON payload.
  /// Uses a fixed IV so the same payload always produces the same code.
  static String deriveShortCode(String json) {
    try {
      final encrypted = _encrypter.encrypt(json, iv: _iv);
      final bytes = encrypted.bytes;
      // Convert first 5 bytes to a 40-bit number, then Base36-encode to 6+ chars.
      int value = 0;
      for (int i = 0; i < 5; i++) {
        value = (value << 8) | bytes[i];
      }
      return _toBase36(value).toUpperCase().padLeft(6, '0').substring(0, 6);
    } catch (e) {
      throw SetupCryptoException('Failed to derive short code: $e');
    }
  }

  static String _toBase36(int value) {
    if (value == 0) return '0';
    const chars = '0123456789abcdefghijklmnopqrstuvwxyz';
    final buffer = StringBuffer();
    while (value > 0) {
      buffer.write(chars[value % 36]);
      value ~/= 36;
    }
    return buffer.toString().split('').reversed.join();
  }
}
