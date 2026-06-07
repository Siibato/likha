import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/domain/auth/usecases/activate_account.dart';
import 'package:likha/domain/auth/usecases/check_username.dart';
import 'package:likha/domain/auth/usecases/get_current_user.dart';
import 'package:likha/domain/auth/usecases/login.dart';
import 'package:likha/domain/auth/usecases/logout.dart';

// Auth State
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final bool isInitialized;
  final String? pendingActivationUsername;
  final String? pendingActivationFullName;
  final String? loginUsername;
  final int? attemptsRemaining;
  final int? lockoutRemainingSeconds;
  final int? lockoutLevel;
  final bool pendingForceLogout;
  final int pendingSyncCount;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.isInitialized = false,
    this.pendingActivationUsername,
    this.pendingActivationFullName,
    this.loginUsername,
    this.attemptsRemaining,
    this.lockoutRemainingSeconds,
    this.lockoutLevel,
    this.pendingForceLogout = false,
    this.pendingSyncCount = 0,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    bool? isInitialized,
    String? pendingActivationUsername,
    String? pendingActivationFullName,
    String? loginUsername,
    int? attemptsRemaining,
    int? lockoutRemainingSeconds,
    int? lockoutLevel,
    bool? pendingForceLogout,
    int? pendingSyncCount,
    bool clearError = false,
    bool clearUser = false,
    bool clearPendingActivation = false,
    bool clearLoginUsername = false,
    bool clearAttempts = false,
    bool clearLockout = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isInitialized: isInitialized ?? this.isInitialized,
      pendingActivationUsername: clearPendingActivation
          ? null
          : (pendingActivationUsername ?? this.pendingActivationUsername),
      pendingActivationFullName: clearPendingActivation
          ? null
          : (pendingActivationFullName ?? this.pendingActivationFullName),
      loginUsername: clearLoginUsername
          ? null
          : (loginUsername ?? this.loginUsername),
      attemptsRemaining: clearAttempts ? null : (attemptsRemaining ?? this.attemptsRemaining),
      lockoutRemainingSeconds: clearLockout ? null : (lockoutRemainingSeconds ?? this.lockoutRemainingSeconds),
      lockoutLevel: clearLockout ? null : (lockoutLevel ?? this.lockoutLevel),
      pendingForceLogout: pendingForceLogout ?? this.pendingForceLogout,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
    );
  }
}

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final Login _login;
  final Logout _logout;
  final GetCurrentUser _getCurrentUser;
  final CheckUsername _checkUsername;
  final ActivateAccount _activateAccount;
  final SyncQueue _syncQueue;
  Timer? _lockoutTimer;

  AuthNotifier(
    this._login,
    this._logout,
    this._getCurrentUser,
    this._checkUsername,
    this._activateAccount,
    this._syncQueue,
  ) : super(AuthState());

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  void _startLockoutCountdown(int seconds) {
    _lockoutTimer?.cancel();
    int remaining = seconds;
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining--;
      if (remaining <= 0) {
        timer.cancel();
        state = state.copyWith(clearLockout: true);
      } else {
        state = state.copyWith(lockoutRemainingSeconds: remaining);
      }
    });
  }

  Future<void> checkUsernameForLogin(String username) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _checkUsername(username);

    result.fold(
      (failure) {
        String errorMessage;
        // Special handling for username not found errors
        if (failure is ServerFailure && 
            failure.statusCode == 404 && 
            failure.message.contains('Username does not exist')) {
          errorMessage = 'Username does not exist';
        } else {
          errorMessage = AppErrorMapper.fromFailureAuth(failure);
        }
        
        state = state.copyWith(
          isLoading: false,
          error: errorMessage,
        );
      },
      (checkResult) {
        if (checkResult.isPendingActivation) {
          state = state.copyWith(
            isLoading: false,
            pendingActivationUsername: checkResult.username,
            pendingActivationFullName: checkResult.fullName,
            clearError: true,
          );
        } else if (checkResult.isLocked) {
          state = state.copyWith(
            isLoading: false,
            error: 'This account is locked. Contact an administrator.',
          );
        } else {
          // Account is activated, proceed to password entry
          state = state.copyWith(
            isLoading: false,
            loginUsername: checkResult.username,
            clearError: true,
          );
        }
      },
    );
  }

  Future<void> login({
    required String username,
    required String password,
    String? deviceId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _login(LoginParams(
      username: username,
      password: password,
      deviceId: deviceId,
    ));

    result.fold(
      (failure) {
        if (failure is TooManyRequestsFailure) {
          debugPrint('[AUTH] TooManyRequestsFailure - remainingSeconds: ${failure.remainingSeconds}');
          state = state.copyWith(
            isLoading: false,
            clearAttempts: true,
            lockoutRemainingSeconds: failure.remainingSeconds,
            clearError: true,
          );
          debugPrint('[AUTH] State updated - lockoutRemainingSeconds: ${state.lockoutRemainingSeconds}');
          _startLockoutCountdown(failure.remainingSeconds);
        } else if (failure is InvalidCredentialsFailure) {
          debugPrint('[AUTH] InvalidCredentialsFailure - attemptsRemaining: ${failure.attemptsRemaining}');
          state = state.copyWith(
            isLoading: false,
            attemptsRemaining: failure.attemptsRemaining,
            clearError: true,
          );
          debugPrint('[AUTH] State updated - attemptsRemaining: ${state.attemptsRemaining}');
        } else if (failure is ActivationRequiredFailure) {
          state = state.copyWith(
            isLoading: false,
            pendingActivationUsername: failure.username,
            pendingActivationFullName: failure.fullName,
            clearError: true,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            error: AppErrorMapper.fromFailureAuth(failure),
          );
        }
      },
      (user) {
        state = state.copyWith(
          isLoading: false,
          user: user,
          isAuthenticated: true,
          clearError: true,
          clearPendingActivation: true,
          clearLoginUsername: true,
        );
      },
    );
  }

  Future<void> activateAccount({
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _activateAccount(ActivateAccountParams(
      username: username,
      password: password,
      confirmPassword: confirmPassword,
    ));

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: AppErrorMapper.fromFailure(failure),
        );
      },
      (user) {
        state = state.copyWith(
          isLoading: false,
          user: user,
          isAuthenticated: true,
          clearError: true,
          clearPendingActivation: true,
        );
      },
    );
  }

  void clearPendingActivation() {
    state = state.copyWith(clearPendingActivation: true, clearError: true);
  }

  void clearLoginUsername() {
    _lockoutTimer?.cancel();
    state = state.copyWith(clearLoginUsername: true, clearError: true, clearLockout: true, clearAttempts: true);
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    final result = await _logout();

    result.fold(
      (failure) {
        state = AuthState(isInitialized: true);
      },
      (_) {
        state = AuthState(isInitialized: true);
      },
    );
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);

    final result = await _getCurrentUser();

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          isInitialized: true,
          clearUser: true,
        );
      },
      (user) {
        state = state.copyWith(
          isLoading: false,
          user: user,
          isAuthenticated: true,
          isInitialized: true,
        );
      },
    );
  }

  Future<void> getCurrentUser() async {
    state = state.copyWith(isLoading: true);

    final result = await _getCurrentUser();

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: AppErrorMapper.fromFailure(failure),
        );
      },
      (user) {
        state = state.copyWith(
          isLoading: false,
          user: user,
          isAuthenticated: true,
        );
      },
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Called by DioClient when refresh token is invalid and auth is irrecoverable.
  /// Checks for pending sync operations and shows warning if needed.
  Future<void> forceLogout() async {
    final count = await _syncQueue.getPendingCount();
    if (count > 0) {
      state = state.copyWith(pendingForceLogout: true, pendingSyncCount: count);
    } else {
      state = AuthState(isInitialized: true);
    }
  }

  /// Called when user confirms force logout (taps OK on warning dialog).
  /// Clears all user data and returns to login screen.
  Future<void> confirmForceLogout() async {
    // clearAllUserData() was already called in the logout() repository method via DioClient
    // but we also clear auth cache here to ensure everything is gone
    state = AuthState(isInitialized: true);
  }
}
