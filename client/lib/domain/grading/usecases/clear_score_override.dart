import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class ClearScoreOverride {
  final GradingRepository _repository;

  ClearScoreOverride(this._repository);

  ResultVoid call(String scoreId) {
    return _repository.clearScoreOverride(scoreId: scoreId);
  }
}
