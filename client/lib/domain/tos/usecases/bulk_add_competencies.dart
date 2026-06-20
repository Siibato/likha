import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/domain/tos/repositories/tos_repository.dart';

class BulkAddCompetencies {
  final TosRepository _repository;

  BulkAddCompetencies(this._repository);

  ResultFuture<MutationResult<List<TosCompetency>>> call({
    required String tosId,
    required List<Map<String, dynamic>> competencies,
  }) {
    return _repository.bulkAddCompetencies(
        tosId: tosId, competencies: competencies);
  }
}
