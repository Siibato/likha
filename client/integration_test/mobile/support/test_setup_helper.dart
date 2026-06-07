import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:likha/core/sync/sync_manager.dart';
import 'package:likha/injection_container.dart' as di;
import 'package:likha/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestSetupHelper {
  static Future<void> resetAppState() async {
    if (di.sl.isRegistered<SyncManager>()) {
      di.sl<SyncManager>().reset();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (di.sl.isRegistered<StorageService>()) {
      await di.sl<StorageService>().clearAuthData();
    }

    GetIt.instance.reset();

    const testServerUrl = String.fromEnvironment(
      'TEST_SERVER_URL',
      defaultValue: 'http://10.0.2.2:8080',
    );

    dotenv.testLoad(fileInput: '''
API_BASE_URL=$testServerUrl
SYNC_LOGGING_ENABLED=false
CORE_LOGGING_ENABLED=false
VALIDATION_LOGGING_ENABLED=false
CACHE_LOGGING_ENABLED=false
REPO_LOGGING_ENABLED=false
PROVIDER_LOGGING_ENABLED=false
PAGE_LOGGING_ENABLED=false
DEV_MODE=false
''');
  }
}
