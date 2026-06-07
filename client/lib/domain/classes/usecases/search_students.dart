import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/domain/classes/repositories/class_repository.dart';

class SearchStudents {
  final ClassRepository _repository;

  SearchStudents(this._repository);

  ResultFuture<List<User>> call({String? query}) {
    return _repository.searchStudents(query: query);
  }
}
