import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/grading/entities/quarterly_grade.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class GetQuarterlyGrades {
  final GradingRepository _repository;

  GetQuarterlyGrades(this._repository);

  ResultFuture<List<QuarterlyGrade>> call({
    required String classId,
    required int quarter,
  }) {
    return _repository.getQuarterlyGrades(classId: classId, quarter: quarter);
  }
}
