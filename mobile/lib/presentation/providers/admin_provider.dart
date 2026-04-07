import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/auth/entities/activity_log.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/domain/auth/usecases/check_username.dart';
import 'package:likha/domain/auth/usecases/create_account.dart';
import 'package:likha/domain/auth/usecases/get_activity_logs.dart';
import 'package:likha/domain/auth/usecases/get_all_accounts.dart';
import 'package:likha/domain/auth/usecases/lock_account.dart';
import 'package:likha/domain/auth/usecases/reset_account.dart';
import 'package:likha/domain/auth/usecases/delete_account.dart';
import 'package:likha/domain/auth/usecases/update_account.dart';
import 'package:likha/injection_container.dart';

class AdminState {
  final List<User> accounts;
  final List<ActivityLog> activityLogs;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  AdminState({
    this.accounts = const [],
    this.activityLogs = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  AdminState copyWith({
    List<User>? accounts,
    List<ActivityLog>? activityLogs,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AdminState(
      accounts: accounts ?? this.accounts,
      activityLogs: activityLogs ?? this.activityLogs,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class AdminNotifier extends StateNotifier<AdminState> {
  final GetAllAccounts _getAllAccounts;
  final CheckUsername _checkUsername;
  final CreateAccount _createAccount;
  final ResetAccount _resetAccount;
  final LockAccount _lockAccount;
  final GetActivityLogs _getActivityLogs;
  final UpdateAccount _updateAccount;
  final DeleteAccount _deleteAccount;

  AdminNotifier(
    this._getAllAccounts,
    this._checkUsername,
    this._createAccount,
    this._resetAccount,
    this._lockAccount,
    this._getActivityLogs,
    this._updateAccount,
    this._deleteAccount,
  ) : super(AdminState());

  Future<void> loadAccounts() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _getAllAccounts();

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (accounts) => state = state.copyWith(
        isLoading: false,
        accounts: accounts,
      ),
    );
  }

  Future<void> createAccount({
    required String username,
    required String fullName,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    final checkResult = await _checkUsername(username);

    final usernameExists = checkResult.fold(
      (failure) {
        return state.accounts.any(
          (account) => account.username.toLowerCase() == username.toLowerCase(),
        );
      },
      (result) => true,
    );

    if (usernameExists) {
      state = state.copyWith(
        isLoading: false,
        error: 'Username already exists. Please choose a different username.',
      );
      return;
    }

    final result = await _createAccount(CreateAccountParams(
      username: username,
      fullName: fullName,
      role: role,
    ));

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (user) {
        state = state.copyWith(
          isLoading: false,
          accounts: [user, ...state.accounts],
          successMessage: 'Account created successfully',
        );
      },
    );
  }

  Future<void> resetAccount(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    final result = await _resetAccount(userId);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (updatedUser) {
        final updatedAccounts = state.accounts.map((a) {
          return a.id == updatedUser.id ? updatedUser : a;
        }).toList();
        state = state.copyWith(
          isLoading: false,
          accounts: updatedAccounts,
          successMessage: 'Account reset successfully',
        );
      },
    );
  }

  Future<void> lockAccount(String userId, bool locked, {String? reason}) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    final result = await _lockAccount(LockAccountParams(
      userId: userId,
      locked: locked,
      reason: reason,
    ));

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (updatedUser) {
        final updatedAccounts = state.accounts.map((a) {
          return a.id == updatedUser.id ? updatedUser : a;
        }).toList();
        state = state.copyWith(
          isLoading: false,
          accounts: updatedAccounts,
          successMessage: locked ? 'Account locked' : 'Account unlocked',
        );
      },
    );
  }

  Future<void> loadActivityLogs(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _getActivityLogs(userId);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (logs) => state = state.copyWith(
        isLoading: false,
        activityLogs: logs,
      ),
    );
  }

  void clearActivityLogs() {
    state = state.copyWith(activityLogs: []);
  }

  Future<void> updateAccount({
    required String userId,
    String? fullName,
    String? role,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    final result = await _updateAccount(UpdateAccountParams(
      userId: userId,
      fullName: fullName,
      role: role,
    ));

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (updatedUser) {
        final updatedAccounts = state.accounts.map((a) {
          return a.id == updatedUser.id ? updatedUser : a;
        }).toList();
        state = state.copyWith(
          isLoading: false,
          accounts: updatedAccounts,
          successMessage: 'Account updated successfully',
        );
      },
    );
  }

  Future<void> deleteAccount(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    final result = await _deleteAccount(userId: userId);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (_) => state = state.copyWith(
        isLoading: false,
        accounts: state.accounts.where((a) => a.id != userId).toList(),
        successMessage: 'Account deleted successfully',
      ),
    );
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  Future<void> cacheAccountsOffline() async {
    try {
      final result = await _getAllAccounts();
      result.fold(
        (failure) {
        },
        (accounts) {
          state = state.copyWith(accounts: accounts);
        },
      );
    } catch (e) {
      // Silently ignore
    }
  }
}

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  return AdminNotifier(
    sl<GetAllAccounts>(),
    sl<CheckUsername>(),
    sl<CreateAccount>(),
    sl<ResetAccount>(),
    sl<LockAccount>(),
    sl<GetActivityLogs>(),
    sl<UpdateAccount>(),
    sl<DeleteAccount>(),
  );
});
