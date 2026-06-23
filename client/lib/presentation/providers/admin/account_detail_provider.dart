import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/auth/entities/teacher_details.dart';
import 'package:likha/domain/auth/usecases/get_account_details.dart';
import 'package:likha/domain/auth/usecases/upsert_account_details.dart';
import 'package:likha/domain/student_records/entities/learner_details.dart';
import 'package:likha/injection_container.dart';

class AccountDetailState {
  final LearnerDetails? learnerDetails;
  final TeacherDetails? teacherDetails;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  AccountDetailState({
    this.learnerDetails,
    this.teacherDetails,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  AccountDetailState copyWith({
    LearnerDetails? learnerDetails,
    TeacherDetails? teacherDetails,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearDetails = false,
  }) {
    return AccountDetailState(
      learnerDetails: clearDetails ? null : (learnerDetails ?? this.learnerDetails),
      teacherDetails: clearDetails ? null : (teacherDetails ?? this.teacherDetails),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class AccountDetailNotifier extends StateNotifier<AccountDetailState> {
  final Ref ref;
  final GetAccountDetails _getAccountDetails;
  final UpsertAccountDetails _upsertAccountDetails;

  AccountDetailNotifier(this.ref, this._getAccountDetails, this._upsertAccountDetails)
      : super(AccountDetailState());

  Future<void> loadAccountDetails(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _getAccountDetails(userId);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (response) => state = state.copyWith(
        isLoading: false,
        learnerDetails: response.learnerDetails,
        teacherDetails: response.teacherDetails,
      ),
    );
  }

  Future<void> updateAccountDetails({
    required String userId,
    Map<String, dynamic>? learnerDetails,
    Map<String, dynamic>? teacherDetails,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _upsertAccountDetails(UpsertAccountDetailsParams(
      userId: userId,
      learnerDetails: learnerDetails,
      teacherDetails: teacherDetails,
    ));

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: AppErrorMapper.fromFailure(failure),
      ),
      (response) {
        state = state.copyWith(
          isLoading: false,
          learnerDetails: response.learnerDetails,
          teacherDetails: response.teacherDetails,
          successMessage: 'Account details updated successfully',
        );
        ref.invalidate(accountDetailProvider);
      },
    );
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  void clearDetails() {
    state = state.copyWith(clearDetails: true);
  }
}

final accountDetailProvider =
    StateNotifierProvider<AccountDetailNotifier, AccountDetailState>((ref) {
  return AccountDetailNotifier(
    ref,
    sl<GetAccountDetails>(),
    sl<UpsertAccountDetails>(),
  );
});
