import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';

class DeleteFile {
  final AssignmentRepository _repository;

  DeleteFile(this._repository);

  ResultFuture<MutationResult<void>> call(String fileId) {
    return _repository.deleteFile(fileId: fileId);
  }
}
