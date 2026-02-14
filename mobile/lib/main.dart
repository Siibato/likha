import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:likha/core/sync/sync_manager.dart';
import 'package:likha/injection_container.dart' as di;
import 'package:likha/presentation/pages/home_page.dart';
import 'package:likha/presentation/pages/login_page.dart';
import 'package:likha/presentation/widgets/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
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
