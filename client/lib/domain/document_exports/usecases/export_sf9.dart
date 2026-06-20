import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/document_exports/repositories/document_export_repository.dart';

class ExportSf9 {
  final DocumentExportRepository _repository;

  ExportSf9(this._repository);

  ResultFuture<List<int>> call({
    required String classId,
    required String studentId,
  }) {
    return _repository.exportSf9Pdf(classId: classId, studentId: studentId);
  }
}
