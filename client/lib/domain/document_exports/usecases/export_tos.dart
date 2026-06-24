import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/document_exports/repositories/document_export_repository.dart';

class ExportTos {
  final DocumentExportRepository _repository;

  ExportTos(this._repository);

  ResultFuture<List<int>> call({
    required String tosId,
  }) {
    return _repository.exportTosExcel(tosId: tosId);
  }
}
