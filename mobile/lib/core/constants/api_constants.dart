import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  ApiConstants._();

  /// Set at app boot from the stored school config (SharedPreferences).
  /// Falls back to dotenv / hardcoded default if not yet configured.
  static String? _runtimeBaseUrl;

  static void setRuntimeBaseUrl(String url) => _runtimeBaseUrl = url;

  static String get baseUrl =>
      _runtimeBaseUrl ??
      dotenv.env['API_BASE_URL'] ??
      'http://192.168.1.1:8080';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
