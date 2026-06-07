import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/domain/tos/repositories/tos_repository.dart';

class CreateTos {
  final TosRepository _repository;

  CreateTos(this._repository);

  ResultFuture<TableOfSpecifications> call({
    required String classId,
    required Map<String, dynamic> data,
  }) {
    return _repository.createTos(classId: classId, data: data);
  }
}
