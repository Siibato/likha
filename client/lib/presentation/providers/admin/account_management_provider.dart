import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/logging/provider_logger.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/domain/auth/usecases/create_account.dart';
import 'package:likha/domain/auth/usecases/delete_account.dart';
import 'package:likha/domain/auth/usecases/get_all_accounts.dart';
import 'package:likha/domain/auth/usecases/username_exists.dart';
import 'package:likha/domain/auth/usecases/lock_account.dart';
import 'package:likha/domain/auth/usecases/reset_account.dart';
import 'package:likha/domain/auth/usecases/update_account.dart';
import 'package:likha/injection_container.dart';

class AccountManagementState {
  final List<User> accounts;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  AccountManagementState({
    this.accounts = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  AccountManagementState copyWith({
    List<User>? accounts,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AccountManagementState(
      accounts: accounts ?? this.accounts,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class AccountManagementNotifier extends StateNotifier<AccountManagementState> {
  final Ref ref;
  final GetAllAccounts _getAllAccounts;
  final CreateAccount _createAccount;
  final ResetAccount _resetAccount;
  final LockAccount _lockAccount;
  final UpdateAccount _updateAccount;
  final DeleteAccount _deleteAccount;
  final UsernameExists _usernameExists;

  AccountManagementNotifier(
    this.ref,
    this._getAllAccounts,
    this._createAccount,
    this._resetAccount,
    this._lockAccount,
    this._updateAccount,
    this._deleteAccount,
    this._usernameExists,
  ) : super(AccountManagementState());

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
    required String firstName,
    required String lastName,
    required String role,
    Map<String, dynamic>? learnerDetails,
    Map<String, dynamic>? teacherDetails,
  }) async {
    ProviderLogger.instance.log('createAccount START: username=$username, firstName=$firstName, lastName=$lastName, role=$role');

    final exists = await _usernameExists(username);
    if (exists) {
      ProviderLogger.instance.log('createAccount: Duplicate username detected');
      state = state.copyWith(
        error: 'Username already exists',
      );
      return;
    }

    final previousAccounts = List<User>.from(state.accounts);

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempUser = User(
      id: tempId,
      username: username,
      firstName: firstName,
      lastName: lastName,
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
      firstName: firstName,
      lastName: lastName,
      role: role,
      learnerDetails: learnerDetails,
      teacherDetails: teacherDetails,
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
      (mutationResult) {
        final user = mutationResult.entity;
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
          firstName: a.firstName,
          lastName: a.lastName,
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
      clearError: true,
      clearSuccess: true,
      accounts: optimisticAccounts,
    );

    final result = await _resetAccount(userId);

    result.fold(
      (failure) => state = state.copyWith(
        accounts: previousAccounts,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (mutationResult) {
        final updatedUser = mutationResult.entity;
        state = state.copyWith(
          accounts: state.accounts.map((a) => a.id == updatedUser.id ? updatedUser : a).toList(),
          successMessage: 'Account reset successfully',
        );
        ref.invalidate(accountManagementProvider);
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
          firstName: a.firstName,
          lastName: a.lastName,
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
        accounts: previousAccounts,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (mutationResult) {
        final updatedUser = mutationResult.entity;
        state = state.copyWith(
          accounts: state.accounts.map((a) => a.id == updatedUser.id ? updatedUser : a).toList(),
          successMessage: locked ? 'Account locked' : 'Account unlocked',
        );
        ref.invalidate(accountManagementProvider);
      },
    );
  }

  Future<void> updateAccount({
    required String userId,
    String? firstName,
    String? lastName,
    String? role,
  }) async {
    final previousAccounts = List<User>.from(state.accounts);

    final optimisticAccounts = state.accounts.map((a) {
      if (a.id == userId) {
        return User(
          id: a.id,
          username: a.username,
          firstName: firstName ?? a.firstName,
          lastName: lastName ?? a.lastName,
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
      clearError: true,
      clearSuccess: true,
      accounts: optimisticAccounts,
    );

    final result = await _updateAccount(UpdateAccountParams(
      userId: userId,
      firstName: firstName,
      lastName: lastName,
      role: role,
    ));

    result.fold(
      (failure) => state = state.copyWith(
        accounts: previousAccounts,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (mutationResult) {
        final updatedUser = mutationResult.entity;
        state = state.copyWith(
          accounts: state.accounts.map((a) => a.id == updatedUser.id ? updatedUser : a).toList(),
          successMessage: 'Account updated successfully',
        );
        ref.invalidate(accountManagementProvider);
      },
    );
  }

  Future<void> deleteAccount(String userId) async {
    final previousAccounts = List<User>.from(state.accounts);

    state = state.copyWith(
      clearError: true,
      clearSuccess: true,
      accounts: state.accounts.where((a) => a.id != userId).toList(),
    );

    final result = await _deleteAccount(userId: userId);

    result.fold(
      (failure) => state = state.copyWith(
        accounts: previousAccounts,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (_) {
        state = state.copyWith(
          successMessage: 'Account deleted successfully',
        );
        ref.invalidate(accountManagementProvider);
      },
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

final accountManagementProvider =
    StateNotifierProvider<AccountManagementNotifier, AccountManagementState>((ref) {
  return AccountManagementNotifier(
    ref,
    sl<GetAllAccounts>(),
    sl<CreateAccount>(),
    sl<ResetAccount>(),
    sl<LockAccount>(),
    sl<UpdateAccount>(),
    sl<DeleteAccount>(),
    sl<UsernameExists>(),
  );
});
