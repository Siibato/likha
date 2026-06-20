import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class DeleteGradeItem {
  final GradingRepository _repository;

  DeleteGradeItem(this._repository);

  ResultFuture<MutationResult<void>> call(String id) {
    return _repository.deleteGradeItem(id: id);
  }
}
