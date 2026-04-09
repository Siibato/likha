import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class UpdateQuarterlyGrade {
  final GradingRepository _repository;

  UpdateQuarterlyGrade(this._repository);

  ResultVoid call({
    required String classId,
    required String studentId,
    required int quarter,
    required int transmutedGrade,
  }) {
    return _repository.updateTransmutedGrade(
      classId: classId,
      studentId: studentId,
      quarter: quarter,
      transmutedGrade: transmutedGrade,
    );
  }
}
