import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/tos/repositories/tos_repository.dart';

class DeleteTos {
  final TosRepository _repository;

  DeleteTos(this._repository);

  ResultFuture<MutationResult<void>> call(String tosId) {
    return _repository.deleteTos(tosId: tosId);
  }
}
