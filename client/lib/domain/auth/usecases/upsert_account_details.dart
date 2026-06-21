import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/models/auth/account_detail_response_model.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';

class UpsertAccountDetails {
  final AuthRepository _repository;

  UpsertAccountDetails(this._repository);

  ResultFuture<AccountDetailResponseModel> call(UpsertAccountDetailsParams params) {
    return _repository.upsertAccountDetails(
      userId: params.userId,
      learnerDetails: params.learnerDetails,
      teacherDetails: params.teacherDetails,
    );
  }
}

class UpsertAccountDetailsParams {
  final String userId;
  final Map<String, dynamic>? learnerDetails;
  final Map<String, dynamic>? teacherDetails;

  UpsertAccountDetailsParams({
    required this.userId,
    this.learnerDetails,
    this.teacherDetails,
  });
}
