import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/admin/entities/activity_log.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';

class GetActivityLogs {
  final AuthRepository _repository;

  GetActivityLogs(this._repository);

  ResultFuture<List<ActivityLog>> call(String userId) {
    return _repository.getActivityLogs(userId: userId);
  }
}
