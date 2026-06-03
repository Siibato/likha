import 'encryption_service.dart';

class NoOpEncryptionService implements EncryptionService {
  const NoOpEncryptionService();

  @override
  String encryptField(String? plaintext) => plaintext ?? '';

  @override
  String? decryptField(String? ciphertext) => ciphertext;
}
