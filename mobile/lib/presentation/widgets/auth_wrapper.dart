import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/constants/api_constants.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/core/services/school_setup_service.dart';
import 'package:likha/core/sync/sync_manager.dart';
import 'package:likha/injection_container.dart' as di;
import 'package:likha/presentation/pages/activate_account_page.dart';
import 'package:likha/presentation/pages/admin/school_details_setup_page.dart';
import 'package:likha/presentation/pages/home_page.dart';
import 'package:likha/presentation/pages/login_page.dart';
import 'package:likha/presentation/pages/login_password_page.dart';
import 'package:likha/presentation/pages/school_picker_page.dart';
import 'package:likha/presentation/pages/setup/school_setup_page.dart';
import 'package:likha/presentation/pages/sync_loading_page.dart';
import 'package:likha/presentation/providers/admin_provider.dart';
import 'package:likha/presentation/providers/auth_provider.dart';
import 'package:likha/presentation/providers/sync_provider.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  String? _lastSyncedUserId;
  bool _syncFailureAcknowledged = false;

  // School config check
  bool _schoolConfigInitialized = false;
  bool _hasSchoolConfig = false;

  // Admin school details check (after login)
  bool _adminSchoolDetailsChecked = false;
  bool _adminSchoolDetailsExist = false;

  StreamSubscription<Uri>? _deepLinkSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initSchoolConfig();
      _initDeepLinks();
    });
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    super.dispose();
  }

  Future<void> _initSchoolConfig() async {
    final config = await di.sl<SchoolSetupService>().getSchoolConfig();
    if (config != null) {
      ApiConstants.setRuntimeBaseUrl(config.serverUrl);
    }
    if (!mounted) return;
    setState(() {
      _hasSchoolConfig = config != null;
      _schoolConfigInitialized = true;
    });

    if (_hasSchoolConfig) {
      // Wire up force-logout so invalid tokens auto-navigate to login
      di.sl<DioClient>().onForceLogout = () {
        ref.read(authProvider.notifier).forceLogout();
      };
      ref.read(authProvider.notifier).checkAuthStatus();
    }
  }

  void _initDeepLinks() {
    if (kIsWeb) return; // Deep links handled differently on web
    _deepLinkSub = AppLinks().uriLinkStream.listen((uri) {
      if (!mounted) return;
      if (uri.scheme == 'likha' &&
          uri.host == 'setup' &&
          uri.queryParameters['server'] == 'cloud') {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SchoolPickerPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Waiting for school config check
    if (!_schoolConfigInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 2. No school config → first-launch setup
    if (!_hasSchoolConfig) {
      return const SchoolSetupPage();
    }

    // 3. School configured — existing auth flow
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (prev, next) {
      if (prev != null && prev.isAuthenticated && !next.isAuthenticated) {
        _lastSyncedUserId = null;
        _syncFailureAcknowledged = false;
        di.sl<SyncManager>().reset();
      }
    });

    if (!authState.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (authState.pendingForceLogout) {
      return _ForceLogoutWarningPage(
        pendingSyncCount: authState.pendingSyncCount,
      );
    }

    if (authState.isAuthenticated) {
      if (_lastSyncedUserId != authState.user?.id) {
        _lastSyncedUserId = authState.user?.id;
        _adminSchoolDetailsChecked = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          di.sl<SyncManager>().start();

          if (authState.user?.role == 'admin') {
            ref.read(adminProvider.notifier).cacheAccountsOffline();
            _checkAdminSchoolDetails();
          } else {
            setState(() {
              _adminSchoolDetailsChecked = true;
              _adminSchoolDetailsExist = true;
            });
          }
        });
      }

      // Admin school details check — block dashboard if not set
      if (authState.user?.role == 'admin' && !_adminSchoolDetailsChecked) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      if (authState.user?.role == 'admin' && !_adminSchoolDetailsExist) {
        return const SchoolDetailsSetupPage();
      }

      final syncState = ref.watch(syncProvider);
      final isFirstSync = syncState.lastSyncAt == null;

      if (isFirstSync && syncState.phase == SyncPhase.syncing) {
        return SyncLoadingPage(onContinueOffline: _acknowledgeSyncFailure);
      }
      if (isFirstSync &&
          !_syncFailureAcknowledged &&
          syncState.phase == SyncPhase.failed) {
        return SyncLoadingPage(onContinueOffline: _acknowledgeSyncFailure);
      }

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

  Future<void> _checkAdminSchoolDetails() async {
    try {
      final response = await di.sl<DioClient>().dio.get(
        '${ApiConstants.baseUrl}/api/v1/setup/info',
      );
      final data = response.data['data'] as Map<String, dynamic>?;
      final schoolName = data?['school_name'] as String?;
      if (mounted) {
        setState(() {
          _adminSchoolDetailsChecked = true;
          _adminSchoolDetailsExist = schoolName != null && schoolName.isNotEmpty;
        });
      }
    } catch (_) {
      // If check fails (e.g., offline), allow access to dashboard
      if (mounted) {
        setState(() {
          _adminSchoolDetailsChecked = true;
          _adminSchoolDetailsExist = true;
        });
      }
    }
  }

  void _acknowledgeSyncFailure() {
    setState(() => _syncFailureAcknowledged = true);
  }
}

class _ForceLogoutWarningPage extends ConsumerWidget {
  final int pendingSyncCount;

  const _ForceLogoutWarningPage({
    required this.pendingSyncCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 64,
                color: Color(0xFFD32F2F),
              ),
              const SizedBox(height: 24),
              const Text(
                'Your session has expired',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2B2B2B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'You had $pendingSyncCount unsaved change(s) that could not be synced.',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF7A7A7A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(authProvider.notifier).confirmForceLogout();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B2B2B),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Log me out',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
