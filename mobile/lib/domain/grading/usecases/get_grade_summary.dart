import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class GetGradeSummary {
  final GradingRepository _repository;

  GetGradeSummary(this._repository);

  ResultFuture<List<Map<String, dynamic>>> call({
    required String classId,
    required int quarter,
  }) {
    return _repository.getGradeSummary(classId: classId, quarter: quarter);
  }
}
