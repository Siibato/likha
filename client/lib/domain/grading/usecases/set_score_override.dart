import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class SetScoreOverride {
  final GradingRepository _repository;

  SetScoreOverride(this._repository);

  ResultVoid call({
    required String scoreId,
    required double overrideScore,
  }) {
    return _repository.setScoreOverride(
      scoreId: scoreId,
      overrideScore: overrideScore,
    );
  }
}
