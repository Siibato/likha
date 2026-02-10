import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/injection_container.dart';
import 'package:likha/presentation/pages/activate_account_page.dart';
import 'package:likha/presentation/pages/home_page.dart';
import 'package:likha/presentation/pages/login_page.dart';
import 'package:likha/presentation/pages/login_password_page.dart';
import 'package:likha/presentation/providers/auth_provider.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Wire up force-logout so invalid tokens auto-navigate to login
      sl<DioClient>().onForceLogout = () {
        ref.read(authProvider.notifier).forceLogout();
      };
      ref.read(authProvider.notifier).checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (!authState.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authState.isAuthenticated) {
      return const HomePage();
    }

    if (authState.pendingActivationUsername != null) {
      return const ActivateAccountPage();
    }

    if (authState.loginUsername != null) {
      return const LoginPasswordPage();
    }

    return const LoginPage();
  }
}
