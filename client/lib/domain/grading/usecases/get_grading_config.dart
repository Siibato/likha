import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/grading/entities/grade_config.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class GetGradingConfig {
  final GradingRepository _repository;

  GetGradingConfig(this._repository);

  ResultFuture<List<GradeConfig>> call(String classId) {
    return _repository.getGradingConfig(classId: classId);
  }
}
