import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/document_exports/repositories/document_export_repository.dart';

class ExportClassGrades {
  final DocumentExportRepository _repository;

  ExportClassGrades(this._repository);

  ResultFuture<List<int>> call({
    required String classId,
    required int termNumber,
    required bool isPdf,
  }) {
    if (isPdf) {
      return _repository.exportClassGradesPdf(classId: classId, termNumber: termNumber);
    }
    return _repository.exportClassGradesExcel(classId: classId, termNumber: termNumber);
  }
}
