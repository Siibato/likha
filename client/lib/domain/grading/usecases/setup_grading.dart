import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/grading/entities/grade_config.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class SetupGrading {
  final GradingRepository _repository;

  SetupGrading(this._repository);

  ResultFuture<MutationResult<List<GradeConfig>>> call(SetupGradingParams params) {
    return _repository.setupGrading(
      classId: params.classId,
      gradeLevel: params.gradeLevel,
      subjectGroup: params.subjectGroup,
      schoolYear: params.schoolYear,
      semester: params.semester,
      wwWeight: params.wwWeight,
      ptWeight: params.ptWeight,
      qaWeight: params.qaWeight,
    );
  }
}

class SetupGradingParams {
  final String classId;
  final String gradeLevel;
  final String subjectGroup;
  final String schoolYear;
  final int? semester;
  final double? wwWeight;
  final double? ptWeight;
  final double? qaWeight;

  SetupGradingParams({
    required this.classId,
    required this.gradeLevel,
    required this.subjectGroup,
    required this.schoolYear,
    this.semester,
    this.wwWeight,
    this.ptWeight,
    this.qaWeight,
  });
}
