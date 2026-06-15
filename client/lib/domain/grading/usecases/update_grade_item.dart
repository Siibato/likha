import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class UpdateGradeItem {
  final GradingRepository _repository;

  UpdateGradeItem(this._repository);

  ResultFuture<MutationResult<void>> call({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return _repository.updateGradeItem(id: id, data: data);
  }
}
