import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:likha/core/sync/sync_manager.dart';
import 'package:likha/core/logging/core_logger.dart';
import 'package:likha/injection_container.dart' as di;
import 'package:likha/presentation/pages/home_page.dart';
import 'package:likha/presentation/pages/login_page.dart';
import 'package:likha/presentation/widgets/auth_wrapper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite for non-Android/iOS platforms
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // .env not found - will use fallback URL
    CoreLogger.instance.warn('.env file not loaded: $e');
  }
  await di.init();

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
