import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';

class DeleteFile {
  final AssignmentRepository _repository;

  DeleteFile(this._repository);

  ResultVoid call(String fileId) {
    return _repository.deleteFile(fileId: fileId);
  }
}
