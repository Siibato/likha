import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_saver/file_saver.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/grading/entities/grade_config.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';

/// Service for generating Excel grade reports
class GradeExcelGenerator {
  /// Generate Excel grade report
  Future<void> generateExcel({
    required String classId,
    required String className,
    required int quarter,
    required List<Participant> students,
    required List<GradeItem> gradeItems,
    required Map<String, List<GradeScore>> scoresByItem,
    required GradeConfig? config,
    required List<Map<String, dynamic>>? summary,
  }) async {
    // For now, create a simple CSV file as Excel
    // In a real implementation, you would use a proper Excel library like 'excel'
    final csvData = _generateCsvData(
      className: className,
      quarter: quarter,
      students: students,
      gradeItems: gradeItems,
      scoresByItem: scoresByItem,
      config: config,
      summary: summary,
    );

    final fileName = '${className}_Q${quarter}_Grades_${DateTime.now().millisecondsSinceEpoch}.csv';
    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: Uint8List.fromList(csvData.codeUnits),
      ext: '.csv',
      mimeType: MimeType.csv,
    );
  }

  String _generateCsvData({
    required String className,
    required int quarter,
    required List<Participant> students,
    required List<GradeItem> gradeItems,
    required Map<String, List<GradeScore>> scoresByItem,
    required GradeConfig? config,
    required List<Map<String, dynamic>>? summary,
  }) {
    final buffer = StringBuffer();
    
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

    // Add header information
    buffer.writeln('CLASS RECORD');
    buffer.writeln(className);
    buffer.writeln('Quarter $quarter');
    buffer.writeln('Generated: ${DateTime.now().toString().split('.')[0]}');
    buffer.writeln('');

    // Build header row
    final headers = ["Learner's Name"];
    
    // Add column headers for each section
    for (int i = 0; i < wwItems.length; i++) {
      headers.add('WW${i + 1}');
    }
    if (wwItems.isNotEmpty) {
      headers.addAll(['WW Total', 'WW HS', 'WW %', 'WW WS']);
    }
    
    for (int i = 0; i < ptItems.length; i++) {
      headers.add('PT${i + 1}');
    }
    if (ptItems.isNotEmpty) {
      headers.addAll(['PT Total', 'PT HS', 'PT %', 'PT WS']);
    }
    
    for (int i = 0; i < qaItems.length; i++) {
      headers.add('QA${i + 1}');
    }
    if (qaItems.isNotEmpty) {
      headers.addAll(['QA Total', 'QA HS', 'QA %', 'QA WS']);
    }
    
    headers.addAll(['Initial', 'QG', 'Remarks']);
    
    buffer.writeln(headers.map((h) => '"$h"').join(','));

    // Add HPS row
    final hpsRow = ['HIGHEST POSSIBLE SCORE'];
    
    for (final item in wwItems) {
      hpsRow.add(item.totalPoints.toStringAsFixed(0));
    }
    if (wwItems.isNotEmpty) {
      final wwHs = wwItems.fold<double>(0.0, (sum, item) => sum + item.totalPoints);
      hpsRow.addAll([
        wwHs.toStringAsFixed(0),
        wwHs.toStringAsFixed(0),
        '100%',
        '${config?.wwWeight ?? 40}%'
      ]);
    }
    
    for (final item in ptItems) {
      hpsRow.add(item.totalPoints.toStringAsFixed(0));
    }
    if (ptItems.isNotEmpty) {
      final ptHs = ptItems.fold<double>(0.0, (sum, item) => sum + item.totalPoints);
      hpsRow.addAll([
        ptHs.toStringAsFixed(0),
        ptHs.toStringAsFixed(0),
        '100%',
        '${config?.ptWeight ?? 40}%'
      ]);
    }
    
    for (final item in qaItems) {
      hpsRow.add(item.totalPoints.toStringAsFixed(0));
    }
    if (qaItems.isNotEmpty) {
      final qaHs = qaItems.fold<double>(0.0, (sum, item) => sum + item.totalPoints);
      hpsRow.addAll([
        qaHs.toStringAsFixed(0),
        qaHs.toStringAsFixed(0),
        '100%',
        '${config?.qaWeight ?? 20}%'
      ]);
    }
    
    hpsRow.addAll(['', '', '']);
    buffer.writeln(hpsRow.map((h) => '"$h"').join(','));

    // Add student rows
    for (int i = 0; i < students.length; i++) {
      final student = students[i];
      final studentScores = scoreLookup[student.student.id] ?? {};
      
      final studentRow = ['${i + 1}. ${student.student.fullName}'];
      
      // Add scores for each section
      for (final item in wwItems) {
        final score = studentScores[item.id]?.effectiveScore;
        studentRow.add(score != null ? score.toStringAsFixed(1) : '');
      }
      if (wwItems.isNotEmpty) {
        final wwTotal = _calculateSectionTotal(studentScores, wwItems);
        final wwHs = wwItems.fold<double>(0.0, (sum, item) => sum + item.totalPoints);
        final wwPct = wwTotal > 0 && wwHs > 0 ? (wwTotal / wwHs) * 100 : null;
        studentRow.addAll([
          wwTotal > 0 ? wwTotal.toStringAsFixed(1) : '',
          wwHs.toStringAsFixed(0),
          wwPct != null ? '${wwPct.toStringAsFixed(1)}%' : '',
          ''
        ]);
      }
      
      for (final item in ptItems) {
        final score = studentScores[item.id]?.effectiveScore;
        studentRow.add(score != null ? score.toStringAsFixed(1) : '');
      }
      if (ptItems.isNotEmpty) {
        final ptTotal = _calculateSectionTotal(studentScores, ptItems);
        final ptHs = ptItems.fold<double>(0.0, (sum, item) => sum + item.totalPoints);
        final ptPct = ptTotal > 0 && ptHs > 0 ? (ptTotal / ptHs) * 100 : null;
        studentRow.addAll([
          ptTotal > 0 ? ptTotal.toStringAsFixed(1) : '',
          ptHs.toStringAsFixed(0),
          ptPct != null ? '${ptPct.toStringAsFixed(1)}%' : '',
          ''
        ]);
      }
      
      for (final item in qaItems) {
        final score = studentScores[item.id]?.effectiveScore;
        studentRow.add(score != null ? score.toStringAsFixed(1) : '');
      }
      if (qaItems.isNotEmpty) {
        final qaTotal = _calculateSectionTotal(studentScores, qaItems);
        final qaHs = qaItems.fold<double>(0.0, (sum, item) => sum + item.totalPoints);
        final qaPct = qaTotal > 0 && qaHs > 0 ? (qaTotal / qaHs) * 100 : null;
        studentRow.addAll([
          qaTotal > 0 ? qaTotal.toStringAsFixed(1) : '',
          qaHs.toStringAsFixed(0),
          qaPct != null ? '${qaPct.toStringAsFixed(1)}%' : '',
          ''
        ]);
      }
      
      // Add summary data
      final qg = qgLookup[student.student.id];
      final remarks = qg != null ? (qg >= 75 ? 'Passed' : 'Failed') : '';
      
      studentRow.addAll([
        '', // Initial grade (calculated separately)
        qg?.toString() ?? '',
        remarks,
      ]);
      
      buffer.writeln(studentRow.map((h) => '"$h"').join(','));
    }

    return buffer.toString();
  }

  double _calculateSectionTotal(
    Map<String, GradeScore> studentScores,
    List<GradeItem> items,
  ) {
    double total = 0;
    for (final item in items) {
      final score = studentScores[item.id]?.effectiveScore;
      if (score != null) {
        total += score;
      }
    }
    return total;
  }
}

/// Provider for GradeExcelGenerator
final gradeExcelGeneratorProvider = Provider<GradeExcelGenerator>((ref) {
  return GradeExcelGenerator();
});
