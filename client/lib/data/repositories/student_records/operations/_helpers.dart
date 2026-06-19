import 'package:likha/injection_container.dart';
import 'package:likha/services/storage_service.dart';

Future<String?> getCurrentUserId() async {
  try {
    return await sl<StorageService>().getUserId();
  } catch (e) {
    return null;
  }
}
