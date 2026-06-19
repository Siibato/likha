import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/logging/service_logger.dart';
import 'package:likha/domain/document_exports/usecases/export_class_grades.dart';
import 'package:likha/domain/document_exports/usecases/export_sf9.dart';
import 'package:likha/domain/document_exports/usecases/export_sf10.dart';
import 'package:likha/injection_container.dart';

class DocumentExportState {
  final bool isExporting;
  final String? error;

  const DocumentExportState({
    this.isExporting = false,
    this.error,
  });

  DocumentExportState copyWith({
    bool? isExporting,
    String? error,
    bool clearError = false,
  }) {
    return DocumentExportState(
      isExporting: isExporting ?? this.isExporting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class DocumentExportNotifier extends StateNotifier<DocumentExportState> {
  final ExportClassGrades _exportClassGrades;
  final ExportSf9 _exportSf9;
  final ExportSf10Pdf _exportSf10Pdf;
  final ExportSf10Excel _exportSf10Excel;

  DocumentExportNotifier(
    this._exportClassGrades,
    this._exportSf9,
    this._exportSf10Pdf,
    this._exportSf10Excel,
  ) : super(const DocumentExportState());

  Future<void> exportClassGrades({
    required String classId,
    required int period,
    required bool isPdf,
  }) async {
    state = state.copyWith(isExporting: true, clearError: true);

    final result = await _exportClassGrades(classId: classId, period: period, isPdf: isPdf);

    result.fold(
      (failure) {
        ServiceLogger.instance.warn('Export failed: ${failure.message}');
        state = state.copyWith(isExporting: false, error: failure.message);
      },
      (bytes) async {
        await _saveBytes(
          bytes: Uint8List.fromList(bytes),
          fileName: 'grades_${isPdf ? 'pdf' : 'excel'}_${DateTime.now().millisecondsSinceEpoch}',
          ext: isPdf ? '.pdf' : '.xlsx',
          mimeType: isPdf ? MimeType.pdf : MimeType.microsoftExcel,
        );
        state = state.copyWith(isExporting: false);
      },
    );
  }

  Future<void> exportSf9({
    required String classId,
    required String studentId,
    required String studentName,
  }) async {
    state = state.copyWith(isExporting: true, clearError: true);

    final result = await _exportSf9(classId: classId, studentId: studentId);

    result.fold(
      (failure) {
        ServiceLogger.instance.warn('SF9 export failed: ${failure.message}');
        state = state.copyWith(isExporting: false, error: failure.message);
      },
      (bytes) async {
        final safeName = studentName.replaceAll(' ', '_');
        await _saveBytes(
          bytes: Uint8List.fromList(bytes),
          fileName: 'SF9_$safeName',
          ext: '.pdf',
          mimeType: MimeType.pdf,
        );
        state = state.copyWith(isExporting: false);
      },
    );
  }

  Future<void> exportSf10Pdf({
    required String classId,
    required String studentId,
    required String studentName,
  }) async {
    state = state.copyWith(isExporting: true, clearError: true);

    final result = await _exportSf10Pdf(classId: classId, studentId: studentId);

    result.fold(
      (failure) {
        ServiceLogger.instance.warn('SF10 PDF export failed: ${failure.message}');
        state = state.copyWith(isExporting: false, error: failure.message);
      },
      (bytes) async {
        final safeName = studentName.replaceAll(' ', '_');
        await _saveBytes(
          bytes: Uint8List.fromList(bytes),
          fileName: 'SF10_$safeName',
          ext: '.pdf',
          mimeType: MimeType.pdf,
        );
        state = state.copyWith(isExporting: false);
      },
    );
  }

  Future<void> exportSf10Excel({
    required String classId,
    required String studentId,
    required String studentName,
  }) async {
    state = state.copyWith(isExporting: true, clearError: true);

    final result = await _exportSf10Excel(classId: classId, studentId: studentId);

    result.fold(
      (failure) {
        ServiceLogger.instance.warn('SF10 Excel export failed: ${failure.message}');
        state = state.copyWith(isExporting: false, error: failure.message);
      },
      (bytes) async {
        final safeName = studentName.replaceAll(' ', '_');
        await _saveBytes(
          bytes: Uint8List.fromList(bytes),
          fileName: 'SF10_$safeName',
          ext: '.xlsx',
          mimeType: MimeType.microsoftExcel,
        );
        state = state.copyWith(isExporting: false);
      },
    );
  }

  Future<void> _saveBytes({
    required Uint8List bytes,
    required String fileName,
    required String ext,
    required MimeType mimeType,
  }) async {
    if (kIsWeb) {
      // On web, rely on browser download via Content-Disposition header
      // The dio bytes response will trigger browser download automatically
      // when using an anchor tag or window.open. For now, FileSaver
      // handles web via its own mechanism.
      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        ext: ext,
        mimeType: mimeType,
      );
    } else {
      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        ext: ext,
        mimeType: mimeType,
      );
    }
  }
}

final documentExportProvider =
    StateNotifierProvider<DocumentExportNotifier, DocumentExportState>((ref) {
  return DocumentExportNotifier(
    sl<ExportClassGrades>(),
    sl<ExportSf9>(),
    sl<ExportSf10Pdf>(),
    sl<ExportSf10Excel>(),
  );
});
