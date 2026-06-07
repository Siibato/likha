import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class GetStudentResults {
  final AssessmentRepository _repository;

  GetStudentResults(this._repository);

  ResultFuture<StudentResult> call(String submissionId) {
    return _repository.getStudentResults(submissionId: submissionId);
  }
}
