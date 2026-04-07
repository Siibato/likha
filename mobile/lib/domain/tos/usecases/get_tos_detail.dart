import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/domain/tos/repositories/tos_repository.dart';

class GetTosDetail {
  final TosRepository _repository;

  GetTosDetail(this._repository);

  ResultFuture<(TableOfSpecifications, List<TosCompetency>)> call(
      String tosId) {
    return _repository.getTosDetail(tosId: tosId);
  }
}
