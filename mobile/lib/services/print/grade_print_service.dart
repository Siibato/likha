import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/grading/entities/grade_config.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';

/// Service for printing grade reports
class GradePrintService {
  GradePrintService();

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
    try {
      // Generate PDF for printing
      final pdf = await _generatePrintPdf(
        className: className,
        quarter: quarter,
        students: students,
        gradeItems: gradeItems,
        scoresByItem: scoresByItem,
        config: config,
        summary: summary,
      );

      // Show print dialog
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => Uint8List.fromList(pdf),
        name: '${className}_Q${quarter}_Grades',
        format: PdfPageFormat.a4.landscape,
      );
    } catch (e) {
      throw Exception('Failed to print grades: $e');
    }
  }

  /// Generate PDF specifically for printing
  Future<List<int>> _generatePrintPdf({
    required String className,
    required int quarter,
    required List<Participant> students,
    required List<GradeItem> gradeItems,
    required Map<String, List<GradeScore>> scoresByItem,
    required GradeConfig? config,
    required List<Map<String, dynamic>>? summary,
  }) async {
    // For now, we'll use the same PDF generation as download
    // In a real implementation, you might want to optimize for printing
    // with different margins, headers, footers, etc.
    
    // Generate the PDF data
    // Note: This is a simplified approach. In a real implementation,
    // you'd modify the PDF generator to return the bytes directly
    // instead of saving to file.
    
    // For now, create a simple PDF for printing
    final pdf = await _createSimplePrintPdf(
      className: className,
      quarter: quarter,
      students: students,
      gradeItems: gradeItems,
      scoresByItem: scoresByItem,
      config: config,
      summary: summary,
    );

    return pdf.save();
  }

  /// Create a simple PDF for printing (placeholder implementation)
  Future<pw.Document> _createSimplePrintPdf({
    required String className,
    required int quarter,
    required List<Participant> students,
    required List<GradeItem> gradeItems,
    required Map<String, List<GradeScore>> scoresByItem,
    required GradeConfig? config,
    required List<Map<String, dynamic>>? summary,
  }) async {
    final pdf = pw.Document();
    
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

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Text(
                'CLASS RECORD',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                className,
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Quarter ${quarter}',
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Generated: ${DateTime.now().toString().split('.')[0]}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
              pw.SizedBox(height: 20),

              // Simple table structure
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black),
                columnWidths: {
                  0: pw.FixedColumnWidth(150), // Name
                  1: pw.FixedColumnWidth(60),  // WW
                  2: pw.FixedColumnWidth(60),  // PT
                  3: pw.FixedColumnWidth(60),  // QA
                  4: pw.FixedColumnWidth(60),  // QG
                  5: pw.FixedColumnWidth(80),  // Remarks
                },
                children: [
                  // Header row
                  pw.TableRow(
                    children: [
                      _buildPrintCell("Learner's Name", isHeader: true),
                      _buildPrintCell('WW', isHeader: true),
                      _buildPrintCell('PT', isHeader: true),
                      _buildPrintCell('QA', isHeader: true),
                      _buildPrintCell('QG', isHeader: true),
                      _buildPrintCell('Remarks', isHeader: true),
                    ],
                  ),
                  // Student rows
                  ...students.asMap().entries.map((entry) {
                    final index = entry.key;
                    final student = entry.value;
                    final studentScores = scoreLookup[student.student.id] ?? {};
                    final qg = qgLookup[student.student.id];
                    final remarks = qg != null ? (qg >= 75 ? 'Passed' : 'Failed') : '';

                    return pw.TableRow(
                      children: [
                        _buildPrintCell('${index + 1}. ${student.student.fullName}'),
                        _buildPrintCell(_getSectionTotal(studentScores, wwItems)),
                        _buildPrintCell(_getSectionTotal(studentScores, ptItems)),
                        _buildPrintCell(_getSectionTotal(studentScores, qaItems)),
                        _buildPrintCell(qg?.toString() ?? ''),
                        _buildPrintCell(remarks),
                      ],
                    );
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildPrintCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        color: isHeader ? PdfColors.grey200 : null,
        border: pw.Border.all(color: PdfColors.black),
      ),
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _getSectionTotal(
    Map<String, GradeScore> studentScores,
    List<GradeItem> items,
  ) {
    double total = 0;
    bool hasScore = false;
    
    for (final item in items) {
      final score = studentScores[item.id]?.effectiveScore;
      if (score != null) {
        total += score;
        hasScore = true;
      }
    }
    
    return hasScore ? total.toStringAsFixed(1) : '';
  }
}

/// Provider for GradePrintService
final gradePrintServiceProvider = Provider<GradePrintService>((ref) {
  return GradePrintService();
});
