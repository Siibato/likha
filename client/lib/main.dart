import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:likha/core/database/sqflite_initializer.dart';
import 'package:likha/core/sync/sync_manager.dart';
import 'package:likha/core/logging/core_logger.dart';
import 'package:likha/data/datasources/local/tos/tos_local_datasource.dart';
import 'package:likha/injection_container.dart' as di;
import 'package:likha/presentation/pages/shared/home_page.dart';
import 'package:likha/presentation/pages/shared/auth/login_page.dart';
import 'package:likha/presentation/widgets/auth_wrapper.dart';

bool _isLegacyJavaScriptObjectDiagnosticsError(Object error) {
  try {
    final msg = error.toString();
    return msg.contains('LegacyJavaScriptObject') && msg.contains('DiagnosticsNode');
  } catch (_) {
    return false;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Prevent the default red error widget from building complex trees that
  // can crash the widget inspector on web when JS interop objects are present.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      color: Colors.red.shade50,
      child: Text(
        'Error: ${details.exception}',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.red.shade900, fontSize: 14),
      ),
    );
  };

  // Wrap presentError so crashes DURING error presentation are caught and
  // the original exception is still logged. This breaks the infinite loop
  // where a secondary LegacyJavaScriptObject error keeps firing every frame.
  final originalPresentError = FlutterError.presentError;
  FlutterError.presentError = (FlutterErrorDetails details) {
    if (_isLegacyJavaScriptObjectDiagnosticsError(details.exception)) {
      debugPrint('[suppressed] LegacyJavaScriptObject diagnostics error');
      debugPrint('Original exception: ${details.exception}');
      debugPrint('Original stack: ${details.stack}');
      return;
    }
    try {
      originalPresentError(details);
    } catch (e, stack) {
      if (_isLegacyJavaScriptObjectDiagnosticsError(e)) {
        debugPrint('[suppressed] LegacyJavaScriptObject during presentError');
        debugPrint('Original exception: ${details.exception}');
        debugPrint('Original stack: ${details.stack}');
        return;
      }
      debugPrint('Crash while presenting error: $e');
      debugPrint(stack.toString());
      debugPrint('Original exception: ${details.exception}');
    }
  };

  FlutterError.onError = (details) {
    if (_isLegacyJavaScriptObjectDiagnosticsError(details.exception)) {
      debugPrint('[suppressed] LegacyJavaScriptObject in onError');
      debugPrint('Original exception: ${details.exception}');
      debugPrint('Original stack: ${details.stack}');
      return;
    }
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (_isLegacyJavaScriptObjectDiagnosticsError(error)) {
      return true;
    }
    return false;
  };

  // Initialize sqflite for non-Android/iOS platforms
  initializeSqflite();
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // .env not found - will use fallback URL
    CoreLogger.instance.warn('.env file not loaded: $e');
  }
  await di.init();

  // Seed MELCs local data if the table is empty
  await GetIt.instance<TosLocalDataSource>().seedMelcsIfEmpty();

  // Start offline sync manager
  final syncManager = GetIt.instance<SyncManager>();
  syncManager.start();

  runApp(const ProviderScope(child: LikhaApp()));
}

class LikhaApp extends StatelessWidget {
  const LikhaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Likha',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
