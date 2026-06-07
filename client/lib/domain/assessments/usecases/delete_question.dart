import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class DeleteQuestion {
  final AssessmentRepository _repository;

  DeleteQuestion(this._repository);

  ResultVoid call(String questionId) {
    return _repository.deleteQuestion(questionId: questionId);
  }
}
