import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class UpdatePeriodGrade {
  final GradingRepository _repository;

  UpdatePeriodGrade(this._repository);

  ResultVoid call({
    required String classId,
    required String studentId,
    required int gradingPeriodNumber,
    required int transmutedGrade,
  }) {
    return _repository.updateTransmutedGrade(
      classId: classId,
      studentId: studentId,
      gradingPeriodNumber: gradingPeriodNumber,
      transmutedGrade: transmutedGrade,
    );
  }
}
