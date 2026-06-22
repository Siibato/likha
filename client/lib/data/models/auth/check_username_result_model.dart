import 'package:likha/domain/auth/entities/check_username_result.dart';

class CheckUsernameResultModel extends CheckUsernameResult {
  const CheckUsernameResultModel({
    required super.username,
    required super.accountStatus,
    super.firstName,
    super.lastName,
  });

  factory CheckUsernameResultModel.fromJson(Map<String, dynamic> json) {
    return CheckUsernameResultModel(
      username: json['username'] as String,
      accountStatus: json['account_status'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
    );
  }
}
