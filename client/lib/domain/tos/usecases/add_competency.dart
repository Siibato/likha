import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/domain/tos/repositories/tos_repository.dart';

class AddCompetency {
  final TosRepository _repository;

  AddCompetency(this._repository);

  ResultFuture<TosCompetency> call({
    required String tosId,
    required Map<String, dynamic> data,
  }) {
    return _repository.addCompetency(tosId: tosId, data: data);
  }
}
