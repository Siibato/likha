import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class CreateGradeItem {
  final GradingRepository _repository;

  CreateGradeItem(this._repository);

  ResultFuture<MutationResult<GradeItem>> call({
    required String classId,
    required Map<String, dynamic> data,
  }) {
    return _repository.createGradeItem(classId: classId, data: data);
  }
}
