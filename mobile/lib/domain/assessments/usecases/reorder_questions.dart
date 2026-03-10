import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class ReorderAllQuestions {
  final AssessmentRepository _repository;

  const ReorderAllQuestions(this._repository);

  ResultVoid call({
    required String assessmentId,
    required List<String> questionIds,
  }) {
    return _repository.reorderQuestions(
      assessmentId: assessmentId,
      questionIds: questionIds,
    );
  }
}
