import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class SaveScores {
  final GradingRepository _repository;

  SaveScores(this._repository);

  ResultVoid call({
    required String gradeItemId,
    required List<Map<String, dynamic>> scores,
  }) {
    return _repository.saveScores(gradeItemId: gradeItemId, scores: scores);
  }
}
