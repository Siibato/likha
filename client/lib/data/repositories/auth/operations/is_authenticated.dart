import 'package:likha/services/storage_service.dart';

Future<bool> isAuthenticated(StorageService storageService) {
  return storageService.isAuthenticated();
}
