import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/grading/entities/grade_config.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';
import 'package:likha/services/pdf/grade_pdf_generator.dart';
import 'package:likha/services/excel/grade_excel_generator.dart';
import 'package:likha/services/print/grade_print_service.dart';

/// Service for exporting grade data to different formats
class GradeExportService {
  final GradePdfGenerator _pdfGenerator;
  final GradeExcelGenerator _excelGenerator;
  final GradePrintService _printService;

  GradeExportService({
    required GradePdfGenerator pdfGenerator,
    required GradeExcelGenerator excelGenerator,
    required GradePrintService printService,
  })  : _pdfGenerator = pdfGenerator,
        _excelGenerator = excelGenerator,
        _printService = printService;

  /// Export grades to PDF format
  Future<void> exportToPdf({
    required String classId,
    required String className,
    required int quarter,
    required List<Participant> students,
    required List<GradeItem> gradeItems,
    required Map<String, List<GradeScore>> scoresByItem,
    required GradeConfig? config,
    required List<Map<String, dynamic>>? summary,
  }) async {
    await _pdfGenerator.generatePdf(
      classId: classId,
      className: className,
      quarter: quarter,
      students: students,
      gradeItems: gradeItems,
      scoresByItem: scoresByItem,
      config: config,
      summary: summary,
    );
  }

  /// Export grades to Excel format
  Future<void> exportToExcel({
    required String classId,
    required String className,
    required int quarter,
    required List<Participant> students,
    required List<GradeItem> gradeItems,
    required Map<String, List<GradeScore>> scoresByItem,
    required GradeConfig? config,
    required List<Map<String, dynamic>>? summary,
  }) async {
    await _excelGenerator.generateExcel(
      classId: classId,
      className: className,
      quarter: quarter,
      students: students,
      gradeItems: gradeItems,
      scoresByItem: scoresByItem,
      config: config,
      summary: summary,
    );
  }

  /// Print grades directly
  Future<void> printGrades({
    required String classId,
    required String className,
    required int quarter,
    required List<Participant> students,
    required List<GradeItem> gradeItems,
    required Map<String, List<GradeScore>> scoresByItem,
    required GradeConfig? config,
    required List<Map<String, dynamic>>? summary,
  }) async {
    await _printService.printGrades(
      classId: classId,
      className: className,
      quarter: quarter,
      students: students,
      gradeItems: gradeItems,
      scoresByItem: scoresByItem,
      config: config,
      summary: summary,
    );
  }

  /// Prepare grade data for export
  GradeExportData prepareExportData({
    required String className,
    required int quarter,
    required List<Participant> students,
    required List<GradeItem> gradeItems,
    required Map<String, List<GradeScore>> scoresByItem,
    required GradeConfig? config,
    required List<Map<String, dynamic>>? summary,
  }) {
    // Filter grade items by quarter
    final quarterItems = gradeItems
        .where((item) => item.gradingPeriodNumber == quarter)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    // Group items by component
    final wwItems = quarterItems.where((i) => i.component == 'ww').toList();
    final ptItems = quarterItems.where((i) => i.component == 'pt').toList();
    final qaItems = quarterItems.where((i) => i.component == 'qa').toList();

    // Build score lookup
    final scoreLookup = <String, Map<String, GradeScore>>{};
    for (final entry in scoresByItem.entries) {
      for (final score in entry.value) {
        scoreLookup
            .putIfAbsent(score.studentId, () => {})[score.gradeItemId] = score;
      }
    }

    // Build QG lookup
    final qgLookup = <String, int?>{};
    for (final row in (summary ?? [])) {
      final sid = row['student_id'] as String?;
      final qg = row['quarterly_grade'];
      if (sid != null) {
        qgLookup[sid] = qg == null
            ? null
            : (qg is double
                ? qg.round()
                : (qg is int ? qg : int.tryParse(qg.toString())));
      }
    }

    return GradeExportData(
      className: className,
      quarter: quarter,
      students: students,
      wwItems: wwItems,
      ptItems: ptItems,
      qaItems: qaItems,
      scoreLookup: scoreLookup,
      qgLookup: qgLookup,
      config: config,
      summary: summary,
    );
  }
}

/// Data structure for grade export
class GradeExportData {
  final String className;
  final int quarter;
  final List<Participant> students;
  final List<GradeItem> wwItems;
  final List<GradeItem> ptItems;
  final List<GradeItem> qaItems;
  final Map<String, Map<String, GradeScore>> scoreLookup;
  final Map<String, int?> qgLookup;
  final GradeConfig? config;
  final List<Map<String, dynamic>>? summary;

  const GradeExportData({
    required this.className,
    required this.quarter,
    required this.students,
    required this.wwItems,
    required this.ptItems,
    required this.qaItems,
    required this.scoreLookup,
    required this.qgLookup,
    required this.config,
    required this.summary,
  });
}

/// Provider for GradeExportService
final gradeExportServiceProvider = Provider<GradeExportService>((ref) {
  return GradeExportService(
    pdfGenerator: ref.read(gradePdfGeneratorProvider),
    excelGenerator: ref.read(gradeExcelGeneratorProvider),
    printService: ref.read(gradePrintServiceProvider),
  );
});
