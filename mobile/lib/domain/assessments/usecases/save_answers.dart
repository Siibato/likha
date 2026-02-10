import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class SaveAnswers {
  final AssessmentRepository _repository;

  SaveAnswers(this._repository);

  ResultVoid call(SaveAnswersParams params) {
    return _repository.saveAnswers(
      submissionId: params.submissionId,
      answers: params.answers,
    );
  }
}

class SaveAnswersParams {
  final String submissionId;
  final List<Map<String, dynamic>> answers;

  SaveAnswersParams({required this.submissionId, required this.answers});
}
