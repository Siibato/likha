import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/domain/tos/repositories/tos_repository.dart';

class GetTosList {
  final TosRepository _repository;

  GetTosList(this._repository);

  ResultFuture<List<TableOfSpecifications>> call(String classId) {
    return _repository.getTosList(classId: classId);
  }
}
