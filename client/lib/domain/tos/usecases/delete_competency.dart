import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/tos/repositories/tos_repository.dart';

class DeleteCompetency {
  final TosRepository _repository;

  DeleteCompetency(this._repository);

  ResultFuture<MutationResult<void>> call(String competencyId) {
    return _repository.deleteCompetency(competencyId: competencyId);
  }
}
