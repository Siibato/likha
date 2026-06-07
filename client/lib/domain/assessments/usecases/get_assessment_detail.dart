import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class GetAssessmentDetail {
  final AssessmentRepository _repository;

  GetAssessmentDetail(this._repository);

  ResultFuture<(Assessment, List<Question>)> call(String assessmentId) {
    return _repository.getAssessmentDetail(assessmentId: assessmentId);
  }
}
