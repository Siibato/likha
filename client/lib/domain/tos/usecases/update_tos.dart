import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/domain/tos/repositories/tos_repository.dart';

class UpdateTos {
  final TosRepository _repository;

  UpdateTos(this._repository);

  ResultFuture<TableOfSpecifications> call({
    required String tosId,
    required Map<String, dynamic> data,
  }) {
    return _repository.updateTos(tosId: tosId, data: data);
  }
}
