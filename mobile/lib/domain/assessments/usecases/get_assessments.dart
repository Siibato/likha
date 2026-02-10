import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class GetAssessments {
  final AssessmentRepository _repository;

  GetAssessments(this._repository);

  ResultFuture<List<Assessment>> call(String classId) {
    return _repository.getAssessments(classId: classId);
  }
}
