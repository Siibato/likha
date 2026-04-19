import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/entities/submission_file.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';

class UploadFile {
  final AssignmentRepository _repository;

  UploadFile(this._repository);

  ResultFuture<SubmissionFile> call(UploadFileParams params) {
    return _repository.uploadFile(
      submissionId: params.submissionId,
      filePath: params.filePath,
      fileName: params.fileName,
      onSendProgress: params.onSendProgress,
    );
  }
}

class UploadFileParams {
  final String submissionId;
  final String filePath;
  final String fileName;
  final void Function(int sent, int total)? onSendProgress;

  UploadFileParams({
    required this.submissionId,
    required this.filePath,
    required this.fileName,
    this.onSendProgress,
  });
}
