import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_saver/file_saver.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/grading/entities/grade_config.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';

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

/// Service for generating PDF grade reports
class GradePdfGenerator {
  static const double _cellWidth = 50.0;
  static const double _cellHeight = 30.0;
  static const double _headerHeight = 40.0;
  static const double _nameColWidth = 120.0;

  /// Generate PDF grade report
  Future<void> generatePdf({
    required String classId,
    required String className,
    required int quarter,
    required List<Participant> students,
    required List<GradeItem> gradeItems,
    required Map<String, List<GradeScore>> scoresByItem,
    required GradeConfig? config,
    required List<Map<String, dynamic>>? summary,
  }) async {
    final pdf = pw.Document();
    final exportData = _prepareData(
      className: className,
      quarter: quarter,
      students: students,
      gradeItems: gradeItems,
      scoresByItem: scoresByItem,
      config: config,
      summary: summary,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(exportData),
              pw.SizedBox(height: 10),
              _buildGradeTable(exportData),
            ],
          );
        },
      ),
    );

    // Save PDF
    final fileName = '${className}_Q${quarter}_Grades_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: await pdf.save(),
      ext: '.pdf',
      mimeType: MimeType.pdf,
    );
  }

  pw.Widget _buildHeader(GradeExportData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'CLASS RECORD',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          data.className,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Quarter ${data.quarter}',
          style: pw.TextStyle(fontSize: 14),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Generated: ${DateTime.now().toString().split('.')[0]}',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
        ),
      ],
    );
  }

  pw.Widget _buildGradeTable(GradeExportData data) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black),
      columnWidths: {
        0: pw.FixedColumnWidth(_nameColWidth),
        ..._buildColumnWidths(data),
      },
      children: [
        _buildSectionHeaders(data),
        _buildColumnHeaders(data),
        _buildHpsRow(data),
        ..._buildStudentRows(data),
      ],
    );
  }

  Map<int, pw.TableColumnWidth> _buildColumnWidths(GradeExportData data) {
    final widths = <int, pw.TableColumnWidth>{};
    int colIndex = 1;

    // Written Works columns
    for (int i = 0; i < data.wwItems.length; i++) {
      widths[colIndex++] = pw.FixedColumnWidth(_cellWidth);
    }
    if (data.wwItems.isNotEmpty) {
      widths[colIndex++] = pw.FixedColumnWidth(_cellWidth); // Total
      widths[colIndex++] = pw.FixedColumnWidth(_cellWidth); // HS
      widths[colIndex++] = pw.FixedColumnWidth(_cellWidth); // %
      widths[colIndex++] = pw.FixedColumnWidth(_cellWidth); // WS
    }

    // Performance Tasks columns
    for (int i = 0; i < data.ptItems.length; i++) {
      widths[colIndex++] = pw.FixedColumnWidth(_cellWidth);
    }
    if (data.ptItems.isNotEmpty) {
      widths[colIndex++] = pw.FixedColumnWidth(_cellWidth); // Total
      widths[colIndex++] = pw.FixedColumnWidth(_cellWidth); // HS
      widths[colIndex++] = pw.FixedColumnWidth(_cellWidth); // %
      widths[colIndex++] = pw.FixedColumnWidth(_cellWidth); // WS
    }

    // Quarterly Assessment columns
    for (int i = 0; i < data.qaItems.length; i++) {
      widths[colIndex++] = pw.FixedColumnWidth(_cellWidth);
    }
    if (data.qaItems.isNotEmpty) {
      widths[colIndex++] = pw.FixedColumnWidth(_cellWidth); // Total
      widths[colIndex++] = pw.FixedColumnWidth(_cellWidth); // HS
      widths[colIndex++] = pw.FixedColumnWidth(_cellWidth); // %
      widths[colIndex++] = pw.FixedColumnWidth(_cellWidth); // WS
    }

    // Summary columns
    widths[colIndex++] = pw.FixedColumnWidth(_cellWidth); // Initial
    widths[colIndex++] = pw.FixedColumnWidth(_cellWidth); // QG
    widths[colIndex++] = pw.FixedColumnWidth(_cellWidth); // Remarks

    return widths;
  }

  pw.TableRow _buildSectionHeaders(GradeExportData data) {
    final cells = <pw.Widget>[
      _buildHeaderCell("Learner's Name"),
    ];

    // Written Works header
    if (data.wwItems.isNotEmpty) {
      cells.add(_buildSectionCell('WRITTEN WORKS (${data.config?.wwWeight ?? 40}%)', 
          _calculateSectionWidth(data.wwItems.length)));
    }

    // Performance Tasks header
    if (data.ptItems.isNotEmpty) {
      cells.add(_buildSectionCell('PERFORMANCE TASKS (${data.config?.ptWeight ?? 40}%)', 
          _calculateSectionWidth(data.ptItems.length)));
    }

    // Quarterly Assessment header
    if (data.qaItems.isNotEmpty) {
      cells.add(_buildSectionCell('QUARTERLY ASSESSMENT (${data.config?.qaWeight ?? 20}%)', 
          _calculateSectionWidth(data.qaItems.length)));
    }

    // Summary header
    cells.add(_buildSectionCell('SUMMARY', _cellWidth * 3));

    return pw.TableRow(children: cells);
  }

  pw.TableRow _buildColumnHeaders(GradeExportData data) {
    final cells = <pw.Widget>[_buildHeaderCell("Learner's Name")];

    // Add column headers for each section
    cells.addAll(_buildSectionColumnHeaders(data.wwItems, 'WW'));
    cells.addAll(_buildSectionColumnHeaders(data.ptItems, 'PT'));
    cells.addAll(_buildSectionColumnHeaders(data.qaItems, 'QA'));

    // Summary columns
    cells.addAll([
      _buildHeaderCell('Initial'),
      _buildHeaderCell('QG'),
      _buildHeaderCell('Remarks'),
    ]);

    return pw.TableRow(children: cells);
  }

  List<pw.Widget> _buildSectionColumnHeaders(List<GradeItem> items, String prefix) {
    final cells = <pw.Widget>[];
    
    for (int i = 0; i < items.length; i++) {
      cells.add(_buildHeaderCell('$prefix${i + 1}'));
    }
    
    if (items.isNotEmpty) {
      cells.addAll([
        _buildHeaderCell('Total'),
        _buildHeaderCell('HS'),
        _buildHeaderCell('%'),
        _buildHeaderCell('WS'),
      ]);
    }
    
    return cells;
  }

  pw.TableRow _buildHpsRow(GradeExportData data) {
    final cells = <pw.Widget>[_buildHeaderCell('HIGHEST POSSIBLE SCORE')];

    // Add HPS for each section
    cells.addAll(_buildSectionHpsCells(data.wwItems, data.config?.wwWeight ?? 40));
    cells.addAll(_buildSectionHpsCells(data.ptItems, data.config?.ptWeight ?? 40));
    cells.addAll(_buildSectionHpsCells(data.qaItems, data.config?.qaWeight ?? 20));

    // Summary HPS (empty)
    cells.addAll([
      _buildHeaderCell(''),
      _buildHeaderCell(''),
      _buildHeaderCell(''),
    ]);

    return pw.TableRow(children: cells);
  }

  List<pw.Widget> _buildSectionHpsCells(List<GradeItem> items, double weight) {
    final cells = <pw.Widget>[];
    
    for (final item in items) {
      cells.add(_buildDataCell(item.totalPoints.toStringAsFixed(0), bold: true));
    }
    
    if (items.isNotEmpty) {
      final totalHs = items.fold<double>(0.0, (sum, item) => sum + item.totalPoints);
      cells.addAll([
        _buildDataCell(totalHs.toStringAsFixed(0), bold: true),
        _buildDataCell(totalHs.toStringAsFixed(0), bold: true),
        _buildDataCell('100%', bold: true),
        _buildDataCell('${weight}%', bold: true),
      ]);
    }
    
    return cells;
  }

  List<pw.TableRow> _buildStudentRows(GradeExportData data) {
    final rows = <pw.TableRow>[];
    
    for (int i = 0; i < data.students.length; i++) {
      final student = data.students[i];
      final studentScores = data.scoreLookup[student.student.id] ?? {};
      
      final cells = <pw.Widget>[_buildDataCell('${i + 1}. ${student.student.fullName}')];
      
      // Add scores for each section
      cells.addAll(_buildStudentSectionCells(studentScores, data.wwItems));
      cells.addAll(_buildStudentSectionCells(studentScores, data.ptItems));
      cells.addAll(_buildStudentSectionCells(studentScores, data.qaItems));
      
      // Add summary data
      final qg = data.qgLookup[student.student.id];
      final remarks = qg != null ? (qg >= 75 ? 'Passed' : 'Failed') : '';
      
      cells.addAll([
        _buildDataCell(''), // Initial grade (calculated separately)
        _buildDataCell(qg?.toString() ?? ''),
        _buildDataCell(remarks),
      ]);
      
      rows.add(pw.TableRow(children: cells));
    }
    
    return rows;
  }

  List<pw.Widget> _buildStudentSectionCells(
    Map<String, GradeScore> studentScores,
    List<GradeItem> items,
  ) {
    final cells = <pw.Widget>[];
    
    for (final item in items) {
      final score = studentScores[item.id]?.effectiveScore;
      cells.add(_buildDataCell(score != null ? score.toStringAsFixed(1) : ''));
    }
    
    if (items.isNotEmpty) {
      // Calculate totals and percentages for this section
      double total = 0;
      double hs = 0;
      bool hasScore = false;
      
      for (final item in items) {
        hs += item.totalPoints;
        final score = studentScores[item.id]?.effectiveScore;
        if (score != null) {
          total += score;
          hasScore = true;
        }
      }
      
      final pct = hasScore && hs > 0 ? (total / hs) * 100 : null;
      
      cells.addAll([
        _buildDataCell(hasScore ? total.toStringAsFixed(1) : ''),
        _buildDataCell(hs.toStringAsFixed(0)),
        _buildDataCell(pct != null ? '${pct.toStringAsFixed(1)}%' : ''),
        _buildDataCell(''), // WS (calculated separately)
      ]);
    }
    
    return cells;
  }

  pw.Widget _buildHeaderCell(String text) {
    return pw.Container(
      width: _cellWidth,
      height: _headerHeight,
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        border: pw.Border.all(color: PdfColors.black),
      ),
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );
  }

  pw.Widget _buildSectionCell(String text, double width) {
    return pw.Container(
      width: width,
      height: _headerHeight,
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey300,
        border: pw.Border.all(color: PdfColors.black),
      ),
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );
  }

  pw.Widget _buildDataCell(String text, {bool bold = false}) {
    return pw.Container(
      width: _cellWidth,
      height: _cellHeight,
      padding: const pw.EdgeInsets.all(2),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
      ),
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ),
    );
  }

  double _calculateSectionWidth(int itemCount) {
    return (itemCount * _cellWidth) + (_cellWidth * 4); // +4 for Total, HS, %, WS
  }

  GradeExportData _prepareData({
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

/// Provider for GradePdfGenerator
final gradePdfGeneratorProvider = Provider<GradePdfGenerator>((ref) {
  return GradePdfGenerator();
});
