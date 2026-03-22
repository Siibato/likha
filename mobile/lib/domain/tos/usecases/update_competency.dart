import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/domain/tos/repositories/tos_repository.dart';

class UpdateCompetency {
  final TosRepository _repository;

  UpdateCompetency(this._repository);

  ResultFuture<TosCompetency> call({
    required String competencyId,
    required Map<String, dynamic> data,
  }) {
    return _repository.updateCompetency(
        competencyId: competencyId, data: data);
  }
}
