import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/models/auth/account_detail_response_model.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';

class GetAccountDetails {
  final AuthRepository _repository;

  GetAccountDetails(this._repository);

  ResultFuture<AccountDetailResponseModel> call(String userId) {
    return _repository.getAccountDetails(userId: userId);
  }
}
