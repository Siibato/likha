import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import 'package:likha/domain/classes/repositories/class_repository.dart';

class GetAllClasses {
  final ClassRepository _repository;

  GetAllClasses(this._repository);

  ResultFuture<List<ClassEntity>> call() {
    return _repository.getAllClasses();
  }
}
