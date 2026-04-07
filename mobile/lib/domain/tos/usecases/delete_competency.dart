import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/tos/repositories/tos_repository.dart';

class DeleteCompetency {
  final TosRepository _repository;

  DeleteCompetency(this._repository);

  ResultVoid call(String competencyId) {
    return _repository.deleteCompetency(competencyId: competencyId);
  }
}
