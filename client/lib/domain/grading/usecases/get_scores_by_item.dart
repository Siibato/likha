import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class GetScoresByItem {
  final GradingRepository _repository;

  GetScoresByItem(this._repository);

  ResultFuture<List<GradeScore>> call(String gradeItemId) {
    return _repository.getScoresByItem(gradeItemId: gradeItemId);
  }
}
