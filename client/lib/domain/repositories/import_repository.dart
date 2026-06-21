import 'package:likha/data/datasources/remote/import/import_remote_datasource.dart';
import 'package:likha/data/models/import/import_preview_model.dart';

class ImportRepository {
  final ImportRemoteDataSource _remoteDataSource;

  ImportRepository(this._remoteDataSource);

  Future<PreviewResponseModel> previewStudentImport(String filePath) {
    return _remoteDataSource.previewStudentImport(filePath);
  }

  Future<ImportResultModel> importStudents(List<Map<String, dynamic>> rows) {
    return _remoteDataSource.importStudents(rows);
  }

  Future<PreviewResponseModel> previewHistoryImport(String filePath, String type) {
    return _remoteDataSource.previewHistoryImport(filePath, type);
  }

  Future<ImportResultModel> importHistory(List<Map<String, dynamic>> rows, String type) {
    return _remoteDataSource.importHistory(rows, type);
  }
}
