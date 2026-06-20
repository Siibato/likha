import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/logging/service_logger.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/grading/entities/grade_config.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';
import 'package:likha/domain/setup/entities/school_details.dart';
import 'package:likha/services/excel/grade_excel_generator.dart';
import 'package:likha/core/utils/transmutation_util.dart';
import 'package:likha/services/pdf/grade_pdf_generator.dart';

/// Section info with items, HPS totals, and weight
class SectionInfo {
  final String label;
  final String abbreviation;
  final double weight;
  final List<GradeItem> items;
  final double hpsTotal;

  SectionInfo({
    required this.label,
    required this.abbreviation,
    required this.weight,
    required this.items,
    required this.hpsTotal,
  });
}

/// Computed values for one student in one section
class SectionResult {
  final List<double?> scores; // per-item scores (null = no score)
  final double? total; // sum of scores
  final double? ps; // percentage score
  final double? ws; // weighted score

  SectionResult({
    required this.scores,
    this.total,
    this.ps,
    this.ws,
  });
}

/// Computed values for one student across all sections
class StudentExportRow {
  final int index;
  final Participant student;
  final SectionResult ww;
  final SectionResult pt;
  final SectionResult qa;
  final double? initialGrade;
  final int? transmutedGrade;
  final String remarks;

  StudentExportRow({
    required this.index,
    required this.student,
    required this.ww,
    required this.pt,
    required this.qa,
    this.initialGrade,
    this.transmutedGrade,
    required this.remarks,
  });
}

/// Full export context including metadata and computed rows
class GradeExportContext {
  final String className;
  final String? gradeLevel;
  final String? section;
  final String? subject;
  final String? teacherName;
  final int quarter;
  final SchoolDetails? schoolDetails;
  final GradeConfig? config;
  final SectionInfo ww;
  final SectionInfo pt;
  final SectionInfo qa;
  final List<StudentExportRow> studentRows;

  const GradeExportContext({
    required this.className,
    this.gradeLevel,
    this.section,
    this.subject,
    this.teacherName,
    required this.quarter,
    this.schoolDetails,
    this.config,
    required this.ww,
    required this.pt,
    required this.qa,
    required this.studentRows,
  });

  String get quarterLabel {
    final q = quarter;
    if (q >= 1 && q <= 4) {
      return 'QUARTER $q';
    }
    return 'QUARTER $q';
  }

  String? get schoolName => schoolDetails?.schoolName;
  String? get region => schoolDetails?.schoolRegion;
  String? get division => schoolDetails?.schoolDivision;
  String? get district => schoolDetails?.schoolDistrict;
  String? get schoolId => schoolDetails?.schoolCode;
  String? get schoolYear => schoolDetails?.schoolYear;
}

/// Service for exporting grade data to different formats
class GradeExportService {
  final GradeExcelGenerator _excelGenerator;
  final GradePdfGenerator _pdfGenerator;

  GradeExportService({
    required GradeExcelGenerator excelGenerator,
    required GradePdfGenerator pdfGenerator,
  })  : _excelGenerator = excelGenerator,
        _pdfGenerator = pdfGenerator;

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
    SchoolDetails? schoolDetails,
    String? teacherName,
    String? gradeLevel,
    String? section,
    String? subject,
  }) async {
    final ctx = _buildContext(
      className: className,
      quarter: quarter,
      students: students,
      gradeItems: gradeItems,
      scoresByItem: scoresByItem,
      config: config,
      summary: summary,
      schoolDetails: schoolDetails,
      teacherName: teacherName,
      gradeLevel: gradeLevel,
      section: section,
      subject: subject,
    );
    await _excelGenerator.generateExcel(ctx);
  }

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
    SchoolDetails? schoolDetails,
    String? teacherName,
    String? gradeLevel,
    String? section,
    String? subject,
  }) async {
    ServiceLogger.instance.log('exportToPdf: Building context with schoolDetails=${schoolDetails != null}');
    if (schoolDetails != null) {
      ServiceLogger.instance.log('exportToPdf: schoolDetails in context - name="${schoolDetails.schoolName}", region="${schoolDetails.schoolRegion}", division="${schoolDetails.schoolDivision}", code="${schoolDetails.schoolCode}", year="${schoolDetails.schoolYear}"');
    } else {
      ServiceLogger.instance.warn('exportToPdf: schoolDetails is NULL in exportToPdf');
    }
    
    final ctx = _buildContext(
      className: className,
      quarter: quarter,
      students: students,
      gradeItems: gradeItems,
      scoresByItem: scoresByItem,
      config: config,
      summary: summary,
      schoolDetails: schoolDetails,
      teacherName: teacherName,
      gradeLevel: gradeLevel,
      section: section,
      subject: subject,
    );
    
    ServiceLogger.instance.log('exportToPdf: Context built - ctx.schoolName="${ctx.schoolName}", ctx.region="${ctx.region}", ctx.division="${ctx.division}", ctx.schoolId="${ctx.schoolId}", ctx.schoolYear="${ctx.schoolYear}"');
    ServiceLogger.instance.log('exportToPdf: Calling generatePdf');
    await _pdfGenerator.generatePdf(ctx);
  }

  /// Build export context with all computed values
  GradeExportContext _buildContext({
    required String className,
    required int quarter,
    required List<Participant> students,
    required List<GradeItem> gradeItems,
    required Map<String, List<GradeScore>> scoresByItem,
    required GradeConfig? config,
    required List<Map<String, dynamic>>? summary,
    SchoolDetails? schoolDetails,
    String? teacherName,
    String? gradeLevel,
    String? section,
    String? subject,
  }) {
    // Filter grade items by quarter
    final quarterItems = gradeItems
        .where((item) => item.termNumber == quarter)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    // Group items by component
    final wwItems = quarterItems
        .where((i) => i.component == 'ww' || i.component == 'written_work')
        .toList();
    final ptItems = quarterItems
        .where((i) => i.component == 'pt' || i.component == 'performance_task')
        .toList();
    final qaItems = quarterItems
        .where((i) => i.component == 'qa' || i.component == 'period_assessment')
        .toList();

    // Build score lookup: studentId -> gradeItemId -> GradeScore
    final scoreLookup = <String, Map<String, GradeScore>>{};
    for (final entry in scoresByItem.entries) {
      for (final score in entry.value) {
        scoreLookup
            .putIfAbsent(score.studentId, () => {})[score.gradeItemId] = score;
      }
    }

    // Build transmuted grade lookup
    ServiceLogger.instance.warn('exportToPdf _buildContext: summary.length=${(summary ?? []).length}');
    if ((summary ?? []).isNotEmpty) {
      ServiceLogger.instance.warn('exportToPdf _buildContext: summary[0] keys=${summary![0].keys.toList()}');
      ServiceLogger.instance.warn('exportToPdf _buildContext: summary[0]=${summary[0]}');
    }
    final tgLookup = <String, int?>{};
    for (final row in (summary ?? [])) {
      final sid = row['student_id'] as String?;
      final tg = row['transmuted_grade'];
      ServiceLogger.instance.warn('exportToPdf _buildContext: raw row student_id=$sid, transmuted_grade=$tg');
      if (sid != null) {
        tgLookup[sid] = tg == null
            ? null
            : (tg is double
                ? tg.round()
                : (tg is int ? tg : int.tryParse(tg.toString())));
      }
    }
    ServiceLogger.instance.warn('exportToPdf _buildContext: transmuted_grade_lookup keys=${tgLookup.keys.length}, transmuted_grade_lookup=$tgLookup');

    // Build sections
    final wwHps = wwItems.fold<double>(0.0, (s, i) => s + i.totalPoints);
    final ptHps = ptItems.fold<double>(0.0, (s, i) => s + i.totalPoints);
    final qaHps = qaItems.fold<double>(0.0, (s, i) => s + i.totalPoints);

    final wwSection = SectionInfo(
      label: 'Written Works',
      abbreviation: 'WW',
      weight: config?.wwWeight ?? 40,
      items: wwItems,
      hpsTotal: wwHps,
    );
    final ptSection = SectionInfo(
      label: 'Performance Tasks',
      abbreviation: 'PT',
      weight: config?.ptWeight ?? 40,
      items: ptItems,
      hpsTotal: ptHps,
    );
    final qaSection = SectionInfo(
      label: 'Quarterly Assessment',
      abbreviation: 'QA',
      weight: config?.qaWeight ?? 20,
      items: qaItems,
      hpsTotal: qaHps,
    );

    // Compute student rows
    final studentRows = <StudentExportRow>[];
    for (int i = 0; i < students.length; i++) {
      final student = students[i];
      final studentScores = scoreLookup[student.student.id] ?? {};

      final wwResult = _computeSection(studentScores, wwSection);
      final ptResult = _computeSection(studentScores, ptSection);
      final qaResult = _computeSection(studentScores, qaSection);

      final initialGrade = _computeInitialGrade(wwResult, ptResult, qaResult);
      final storedTg = tgLookup[student.student.id];
      final tg = storedTg ?? (initialGrade != null ? TransmutationUtil.transmute(initialGrade) : null);
      final remarks = tg != null ? (tg >= 75 ? 'Passed' : 'Failed') : '';
      ServiceLogger.instance.warn('exportToPdf _buildContext: student=${student.student.id} (${student.student.fullName}) storedTg=$storedTg computedTg=${initialGrade != null ? TransmutationUtil.transmute(initialGrade) : null} finalTg=$tg');

      studentRows.add(StudentExportRow(
        index: i + 1,
        student: student,
        ww: wwResult,
        pt: ptResult,
        qa: qaResult,
        initialGrade: initialGrade,
        transmutedGrade: tg,
        remarks: remarks,
      ));
    }

    return GradeExportContext(
      className: className,
      gradeLevel: gradeLevel,
      section: section,
      subject: subject,
      teacherName: teacherName,
      quarter: quarter,
      schoolDetails: schoolDetails,
      config: config,
      ww: wwSection,
      pt: ptSection,
      qa: qaSection,
      studentRows: studentRows,
    );
  }

  /// Compute section results for a single student
  SectionResult _computeSection(
    Map<String, GradeScore> studentScores,
    SectionInfo section,
  ) {
    final scores = <double?>[];
    double total = 0;
    bool hasAnyScore = false;

    for (final item in section.items) {
      final score = studentScores[item.id]?.effectiveScore;
      scores.add(score);
      if (score != null) {
        total += score;
        hasAnyScore = true;
      }
    }

    if (!hasAnyScore || section.hpsTotal <= 0) {
      return SectionResult(scores: scores);
    }

    final ps = (total / section.hpsTotal) * 100;
    final ws = ps * (section.weight / 100);

    return SectionResult(
      scores: scores,
      total: total,
      ps: ps,
      ws: ws,
    );
  }

  /// Compute initial grade from weighted scores
  double? _computeInitialGrade(
    SectionResult ww,
    SectionResult pt,
    SectionResult qa,
  ) {
    double? sum;
    if (ww.ws != null) sum = (sum ?? 0) + ww.ws!;
    if (pt.ws != null) sum = (sum ?? 0) + pt.ws!;
    if (qa.ws != null) sum = (sum ?? 0) + qa.ws!;
    return sum;
  }
}

/// Provider for GradeExportService
final gradeExportServiceProvider = Provider<GradeExportService>((ref) {
  return GradeExportService(
    excelGenerator: ref.read(gradeExcelGeneratorProvider),
    pdfGenerator: ref.read(gradePdfGeneratorProvider),
  );
});
