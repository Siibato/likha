import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/data/models/import/import_preview_model.dart';
import 'package:likha/domain/repositories/import_repository.dart';
import 'package:likha/injection_container.dart';

enum ImportType { students, schoolHistory, subjects, attendance }

enum ImportStatus { idle, uploading, previewing, importing, success, error }

class ImportState {
  final ImportStatus status;
  final PreviewResponseModel? preview;
  final ImportResultModel? result;
  final String? errorMessage;
  final String? selectedFilePath;

  ImportState({
    this.status = ImportStatus.idle,
    this.preview,
    this.result,
    this.errorMessage,
    this.selectedFilePath,
  });

  ImportState copyWith({
    ImportStatus? status,
    PreviewResponseModel? preview,
    ImportResultModel? result,
    String? errorMessage,
    String? selectedFilePath,
  }) {
    return ImportState(
      status: status ?? this.status,
      preview: preview ?? this.preview,
      result: result ?? this.result,
      errorMessage: errorMessage,
      selectedFilePath: selectedFilePath ?? this.selectedFilePath,
    );
  }
}

class ImportNotifier extends StateNotifier<ImportState> {
  final ImportRepository _repository;

  ImportNotifier(this._repository) : super(ImportState());

  void selectFile(String path) {
    state = ImportState(
      status: ImportStatus.idle,
      selectedFilePath: path,
    );
  }

  void reset() {
    state = ImportState();
  }

  Future<void> previewStudentImport(String filePath) async {
    state = state.copyWith(status: ImportStatus.previewing, errorMessage: null);
    try {
      final preview = await _repository.previewStudentImport(filePath);
      state = state.copyWith(status: ImportStatus.idle, preview: preview);
    } catch (e) {
      state = state.copyWith(status: ImportStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> importStudents() async {
    if (state.preview == null) return;
    state = state.copyWith(status: ImportStatus.importing, errorMessage: null);
    try {
      final validRows = state.preview!.rows
          .where((r) => !r.hasErrors)
          .map((r) => r.data)
          .toList();
      final result = await _repository.importStudents(validRows);
      state = state.copyWith(status: ImportStatus.success, result: result);
    } catch (e) {
      state = state.copyWith(status: ImportStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> previewHistoryImport(String filePath, String type) async {
    state = state.copyWith(status: ImportStatus.previewing, errorMessage: null);
    try {
      final preview = await _repository.previewHistoryImport(filePath, type);
      state = state.copyWith(status: ImportStatus.idle, preview: preview);
    } catch (e) {
      state = state.copyWith(status: ImportStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> importHistory(String type) async {
    if (state.preview == null) return;
    state = state.copyWith(status: ImportStatus.importing, errorMessage: null);
    try {
      final validRows = state.preview!.rows
          .where((r) => !r.hasErrors)
          .map((r) => r.data)
          .toList();
      final result = await _repository.importHistory(validRows, type);
      state = state.copyWith(status: ImportStatus.success, result: result);
    } catch (e) {
      state = state.copyWith(status: ImportStatus.error, errorMessage: e.toString());
    }
  }
}

final importProvider = StateNotifierProvider<ImportNotifier, ImportState>((ref) {
  return ImportNotifier(sl<ImportRepository>());
});
