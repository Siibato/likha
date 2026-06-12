import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/logging/provider_logger.dart';
import 'package:likha/domain/auth/entities/activity_log.dart';
import 'package:likha/domain/auth/entities/user.dart';
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
  final CreateAccount _createAccount;
  final ResetAccount _resetAccount;
  final LockAccount _lockAccount;
  final GetActivityLogs _getActivityLogs;
  final UpdateAccount _updateAccount;
  final DeleteAccount _deleteAccount;

  AdminNotifier(
    this._getAllAccounts,
    this._createAccount,
    this._resetAccount,
    this._lockAccount,
    this._getActivityLogs,
    this._updateAccount,
    this._deleteAccount,
  ) : super(AdminState());

  Future<void> loadAccounts() async {
    ProviderLogger.instance.log('loadAccounts: Starting to load accounts');
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _getAllAccounts();

    result.fold(
      (failure) {
        ProviderLogger.instance.error('loadAccounts: Failed to load accounts - ${failure.message}');
        state = state.copyWith(
          isLoading: false,
          error: AppErrorMapper.fromFailure(failure),
        );
      },
      (accounts) {
        ProviderLogger.instance.log('loadAccounts: Successfully loaded ${accounts.length} accounts');
        state = state.copyWith(
          isLoading: false,
          accounts: accounts,
        );
      },
    );
  }

  Future<void> createAccount({
    required String username,
    required String fullName,
    required String role,
  }) async {
    ProviderLogger.instance.log('createAccount START: username=$username, fullName=$fullName, role=$role');
    final previousAccounts = List<User>.from(state.accounts);

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempUser = User(
      id: tempId,
      username: username,
      fullName: fullName,
      role: role,
      accountStatus: 'pending_activation',
      isActive: false,
      activatedAt: null,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
      accounts: [tempUser, ...state.accounts],
    );

    final result = await _createAccount(CreateAccountParams(
      username: username,
      fullName: fullName,
      role: role,
    ));

    result.fold(
      (failure) {
        ProviderLogger.instance.error('createAccount FAILURE: ${failure.runtimeType} - ${failure.message}');
        final userMessage = AppErrorMapper.fromFailure(failure);
        ProviderLogger.instance.log('User message: $userMessage');
        state = state.copyWith(
          isLoading: false,
          accounts: previousAccounts,
          error: userMessage,
        );
      },
      (user) {
        ProviderLogger.instance.log('createAccount SUCCESS: user id=${user.id}, username=${user.username}');
        state = state.copyWith(
          isLoading: false,
          accounts: state.accounts.map((a) => a.id == tempId ? user : a).toList(),
          successMessage: 'Account created successfully',
        );
      },
    );
  }

  Future<void> resetAccount(String userId) async {
    final previousAccounts = List<User>.from(state.accounts);

    final optimisticAccounts = state.accounts.map((a) {
      if (a.id == userId) {
        return User(
          id: a.id,
          username: a.username,
          fullName: a.fullName,
          role: a.role,
          accountStatus: 'pending_activation',
          isActive: false,
          activatedAt: null,
          createdAt: a.createdAt,
        );
      }
      return a;
    }).toList();

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
      accounts: optimisticAccounts,
    );

    final result = await _resetAccount(userId);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        accounts: previousAccounts,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (updatedUser) {
        state = state.copyWith(
          isLoading: false,
          accounts: state.accounts.map((a) => a.id == updatedUser.id ? updatedUser : a).toList(),
          successMessage: 'Account reset successfully',
        );
      },
    );
  }

  Future<void> lockAccount(String userId, bool locked, {String? reason}) async {
    final previousAccounts = List<User>.from(state.accounts);

    final optimisticAccounts = state.accounts.map((a) {
      if (a.id == userId) {
        return User(
          id: a.id,
          username: a.username,
          fullName: a.fullName,
          role: a.role,
          accountStatus: locked ? 'locked' : 'activated',
          isActive: !locked,
          activatedAt: a.activatedAt,
          createdAt: a.createdAt,
        );
      }
      return a;
    }).toList();

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
      accounts: optimisticAccounts,
    );

    final result = await _lockAccount(LockAccountParams(
      userId: userId,
      locked: locked,
      reason: reason,
    ));

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        accounts: previousAccounts,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (updatedUser) {
        state = state.copyWith(
          isLoading: false,
          accounts: state.accounts.map((a) => a.id == updatedUser.id ? updatedUser : a).toList(),
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
    final previousAccounts = List<User>.from(state.accounts);

    final optimisticAccounts = state.accounts.map((a) {
      if (a.id == userId) {
        return User(
          id: a.id,
          username: a.username,
          fullName: fullName ?? a.fullName,
          role: role ?? a.role,
          accountStatus: a.accountStatus,
          isActive: a.isActive,
          activatedAt: a.activatedAt,
          createdAt: a.createdAt,
        );
      }
      return a;
    }).toList();

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
      accounts: optimisticAccounts,
    );

    final result = await _updateAccount(UpdateAccountParams(
      userId: userId,
      fullName: fullName,
      role: role,
    ));

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        accounts: previousAccounts,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (updatedUser) {
        state = state.copyWith(
          isLoading: false,
          accounts: state.accounts.map((a) => a.id == updatedUser.id ? updatedUser : a).toList(),
          successMessage: 'Account updated successfully',
        );
      },
    );
  }

  Future<void> deleteAccount(String userId) async {
    final previousAccounts = List<User>.from(state.accounts);

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
      accounts: state.accounts.where((a) => a.id != userId).toList(),
    );

    final result = await _deleteAccount(userId: userId);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        accounts: previousAccounts,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (_) => state = state.copyWith(
        isLoading: false,
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
    sl<CreateAccount>(),
    sl<ResetAccount>(),
    sl<LockAccount>(),
    sl<GetActivityLogs>(),
    sl<UpdateAccount>(),
    sl<DeleteAccount>(),
  );
});
