import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';

class DownloadFile {
  final AssignmentRepository _repository;

  DownloadFile(this._repository);

  ResultFuture<List<int>> call(String fileId) {
    return _repository.downloadFile(fileId: fileId);
  }
}
