import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class SetupGrading {
  final GradingRepository _repository;

  SetupGrading(this._repository);

  ResultVoid call(SetupGradingParams params) {
    return _repository.setupGrading(
      classId: params.classId,
      gradeLevel: params.gradeLevel,
      subjectGroup: params.subjectGroup,
      schoolYear: params.schoolYear,
      semester: params.semester,
    );
  }
}

class SetupGradingParams {
  final String classId;
  final String gradeLevel;
  final String subjectGroup;
  final String schoolYear;
  final int? semester;

  SetupGradingParams({
    required this.classId,
    required this.gradeLevel,
    required this.subjectGroup,
    required this.schoolYear,
    this.semester,
  });
}
