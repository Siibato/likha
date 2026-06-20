import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/grading/entities/class_grades.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class GetClassGrades {
  final GradingRepository _repository;

  GetClassGrades(this._repository);

  ResultFuture<ClassGrades> call({
    required String classId,
    required int termNumber,
    bool skipBackgroundRefresh = false,
  }) {
    return _repository.getClassGrades(
      classId: classId,
      termNumber: termNumber,
      skipBackgroundRefresh: skipBackgroundRefresh,
    );
  }
}
