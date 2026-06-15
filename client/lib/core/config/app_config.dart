import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static bool get isDev {
    final raw = dotenv.env['DEV_MODE']?.toLowerCase().trim();
    if (raw == null) return true;
    return raw == 'true' || raw == '1';
  }
}
