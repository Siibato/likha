import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class UpdateTermGrade {
  final GradingRepository _repository;

  UpdateTermGrade(this._repository);

  ResultFuture<MutationResult<void>> call({
    required String classId,
    required String studentId,
    required int termNumber,
    required int transmutedGrade,
  }) {
    return _repository.updateTransmutedGrade(
      classId: classId,
      studentId: studentId,
      termNumber: termNumber,
      transmutedGrade: transmutedGrade,
    );
  }
}
