import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_saver/file_saver.dart';
import 'package:likha/services/grade_export_service.dart';

/// Service for generating DepEd-compliant CSV grade reports
class GradeCsvGenerator {
  Future<void> generateCsv(GradeExportContext ctx) async {
    final csv = _buildCsv(ctx);
    final fileName =
        '${ctx.className}_Q${ctx.quarter}_Grades_${DateTime.now().millisecondsSinceEpoch}.csv';
    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: Uint8List.fromList(csv.codeUnits),
      ext: '.csv',
      mimeType: MimeType.csv,
    );
  }

  String _buildCsv(GradeExportContext ctx) {
    final buffer = StringBuffer();

    // DepEd header metadata
    buffer.writeln(_csvRow(['Class Record']));
    buffer.writeln(_csvRow(['(Pursuant to DepEd Order 8 series of 2015)']));
    buffer.writeln(_csvRow([
      'REGION: ${ctx.region ?? ''}',
      'DIVISION: ${ctx.division ?? ''}',
    ]));
    buffer.writeln(_csvRow([
      'SCHOOL NAME: ${ctx.schoolName ?? ''}',
      'SCHOOL ID: ${ctx.schoolId ?? ''}',
      'SCHOOL YEAR: ${ctx.schoolYear ?? ''}',
    ]));
    buffer.writeln(_csvRow([
      'GRADE & SECTION: ${ctx.gradeLevel ?? ''} ${ctx.section ?? ctx.className}',
      'TEACHER: ${ctx.teacherName ?? ''}',
      'SUBJECT: ${ctx.subject ?? ''}',
      ctx.quarterLabel,
    ]));
    buffer.writeln();

    // Column headers
    buffer.writeln(_buildHeaderRow(ctx));
    // HPS row
    buffer.writeln(_buildHpsRow(ctx));
    // Student rows
    for (final row in ctx.studentRows) {
      buffer.writeln(_buildStudentRow(ctx, row));
    }

    return buffer.toString();
  }

  String _buildHeaderRow(GradeExportContext ctx) {
    final cells = <String>["LEARNERS' NAMES"];

    cells.addAll(_sectionHeaders(ctx.ww, 'WW'));
    cells.addAll(_sectionHeaders(ctx.pt, 'PT'));
    cells.addAll(_sectionHeaders(ctx.qa, 'QA'));

    cells.addAll(['Initial Grade', 'Quarterly Grade']);
    return _csvRow(cells);
  }

  List<String> _sectionHeaders(SectionInfo section, String prefix) {
    final cells = <String>[];
    for (int i = 0; i < section.items.length; i++) {
      cells.add('$prefix${i + 1}');
    }
    if (section.items.isNotEmpty) {
      cells.addAll(['Total', 'PS', 'WS']);
    }
    return cells;
  }

  String _buildHpsRow(GradeExportContext ctx) {
    final cells = <String>['HIGHEST POSSIBLE SCORE'];

    cells.addAll(_sectionHps(ctx.ww));
    cells.addAll(_sectionHps(ctx.pt));
    cells.addAll(_sectionHps(ctx.qa));

    cells.addAll(['', '']);
    return _csvRow(cells);
  }

  List<String> _sectionHps(SectionInfo section) {
    final cells = <String>[];
    for (final item in section.items) {
      cells.add(item.totalPoints.toStringAsFixed(0));
    }
    if (section.items.isNotEmpty) {
      cells.addAll([
        section.hpsTotal.toStringAsFixed(0),
        section.hpsTotal.toStringAsFixed(0),
        '${section.weight.toStringAsFixed(0)}%',
      ]);
    }
    return cells;
  }

  String _buildStudentRow(GradeExportContext ctx, StudentExportRow row) {
    final cells = <String>['${row.index}. ${row.student.student.fullName}'];

    cells.addAll(_sectionData(row.ww));
    cells.addAll(_sectionData(row.pt));
    cells.addAll(_sectionData(row.qa));

    cells.add(row.initialGrade != null ? row.initialGrade!.toStringAsFixed(2) : '');
    cells.add(row.transmutedGrade?.toString() ?? '');

    return _csvRow(cells);
  }

  List<String> _sectionData(SectionResult result) {
    final cells = <String>[];
    for (final score in result.scores) {
      cells.add(score != null ? score.toStringAsFixed(1) : '');
    }
    if (result.scores.isNotEmpty) {
      cells.add(result.total != null ? result.total!.toStringAsFixed(1) : '');
      cells.add(result.ps != null ? result.ps!.toStringAsFixed(2) : '');
      cells.add(result.ws != null ? result.ws!.toStringAsFixed(2) : '');
    }
    return cells;
  }

  String _csvRow(List<String> cells) {
    return cells.map(_csvQuote).join(',');
  }

  String _csvQuote(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}

/// Provider for GradeCsvGenerator
final gradeCsvGeneratorProvider = Provider<GradeCsvGenerator>((ref) {
  return GradeCsvGenerator();
});
