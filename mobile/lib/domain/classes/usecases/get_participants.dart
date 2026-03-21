import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/domain/classes/repositories/class_repository.dart';

class GetParticipants {
  final ClassRepository repository;

  GetParticipants(this.repository);

  ResultFuture<List<User>> call({required String classId}) =>
      repository.getParticipants(classId: classId);
}
