import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:likha/core/db/sqflite_initializer.dart';
import 'package:likha/core/sync/sync_manager.dart';
import 'package:likha/core/logging/core_logger.dart';
import 'package:likha/data/datasources/local/tos/tos_local_datasource.dart';
import 'package:likha/injection_container.dart' as di;
import 'package:likha/presentation/pages/home_page.dart';
import 'package:likha/presentation/pages/login_page.dart';
import 'package:likha/presentation/widgets/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
