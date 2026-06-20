import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/document_exports/repositories/document_export_repository.dart';

class ExportSf10Pdf {
  final DocumentExportRepository _repository;

  ExportSf10Pdf(this._repository);

  ResultFuture<List<int>> call({
    required String classId,
    required String studentId,
  }) {
    return _repository.exportSf10Pdf(classId: classId, studentId: studentId);
  }
}

class ExportSf10Excel {
  final DocumentExportRepository _repository;

  ExportSf10Excel(this._repository);

  ResultFuture<List<int>> call({
    required String classId,
    required String studentId,
  }) {
    return _repository.exportSf10Excel(classId: classId, studentId: studentId);
  }
}
