import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/assessment_statistics.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class GetStatistics {
  final AssessmentRepository _repository;

  GetStatistics(this._repository);

  ResultFuture<AssessmentStatistics> call(String assessmentId) {
    return _repository.getStatistics(assessmentId: assessmentId);
  }
}
