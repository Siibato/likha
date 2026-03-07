import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class ReorderAllAssessments {
  final AssessmentRepository _repository;

  const ReorderAllAssessments(this._repository);

  ResultVoid call({
    required String classId,
    required List<String> assessmentIds,
  }) {
    return _repository.reorderAllAssessments(
      classId: classId,
      assessmentIds: assessmentIds,
    );
  }
}
