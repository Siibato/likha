import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:likha/domain/assessments/entities/assessment_statistics.dart';

class ItemAnalysisPrintService {
  static Future<void> printReport(
    BuildContext context,
    AssessmentStatistics stats,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final schoolName = prefs.getString('school_name') ?? '';
    final region = prefs.getString('school_region') ?? '';
    final division = prefs.getString('school_division') ?? '';
    final schoolYear = prefs.getString('school_year') ?? '';

    await Printing.layoutPdf(
      onLayout: (format) async {
        final doc = pw.Document();

        doc.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
            header: (context) => _buildHeader(
              schoolName: schoolName,
              region: region,
              division: division,
              schoolYear: schoolYear,
              title: stats.title,
            ),
            footer: (context) => _buildFooter(context),
            build: (context) => [
              // Test Summary
              if (stats.testSummary != null) ...[
                _buildTestSummary(stats.testSummary!),
                pw.SizedBox(height: 16),
              ],
              // Item Analysis Table
              _buildItemTable(stats.itemAnalysis),
            ],
          ),
        );

        return doc.save();
      },
    );
  }

  static pw.Widget _buildHeader({
    required String schoolName,
    required String region,
    required String division,
    required String schoolYear,
    required String title,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (region.isNotEmpty)
          pw.Text(
            'Republic of the Philippines',
            style: const pw.TextStyle(fontSize: 9),
          ),
        if (region.isNotEmpty)
          pw.Text(
            'Department of Education',
            style: const pw.TextStyle(fontSize: 9),
          ),
        if (region.isNotEmpty)
          pw.Text(region, style: pw.TextStyle(fontSize: 9)),
        if (division.isNotEmpty)
          pw.Text(division, style: pw.TextStyle(fontSize: 9)),
        if (schoolName.isNotEmpty)
          pw.Text(
            schoolName,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        pw.SizedBox(height: 12),
        pw.Text(
          'ITEM ANALYSIS REPORT',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          title,
          style: const pw.TextStyle(fontSize: 11),
        ),
        if (schoolYear.isNotEmpty)
          pw.Text(
            'School Year: $schoolYear',
            style: const pw.TextStyle(fontSize: 9),
          ),
        pw.SizedBox(height: 16),
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 8),
      ],
    );
  }

  static pw.Widget _buildTestSummary(TestSummary summary) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Test Summary',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Items Analyzed: ${summary.totalItemsAnalyzed}',
                  style: const pw.TextStyle(fontSize: 9)),
              pw.Text(
                  'Upper Group: ${summary.upperGroupSize} | Lower Group: ${summary.lowerGroupSize}',
                  style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                  'Mean Difficulty: ${summary.meanDifficulty.toStringAsFixed(2)}',
                  style: const pw.TextStyle(fontSize: 9)),
              pw.Text(
                  'Mean Discrimination: ${summary.meanDiscrimination.toStringAsFixed(2)}',
                  style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Retain: ${summary.retainCount} | Revise: ${summary.reviseCount} | Discard: ${summary.discardCount}',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemTable(List<ItemAnalysis> items) {
    return pw.TableHelper.fromTextArray(
      headers: [
        'Item #',
        'Difficulty (p)',
        'Label',
        'Discrimination (D)',
        'Label',
        'Verdict',
      ],
      data: items.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        return [
          '${i + 1}',
          item.difficultyIndex.toStringAsFixed(2),
          item.difficultyLabel,
          item.discriminationIndex.toStringAsFixed(2),
          item.discriminationLabel,
          item.verdict.toUpperCase(),
        ];
      }).toList(),
      headerStyle: pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF0F0F0),
      ),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
        5: pw.Alignment.center,
      },
      border: pw.TableBorder.all(width: 0.5),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated by Likha LMS',
              style: const pw.TextStyle(fontSize: 7),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 7),
            ),
          ],
        ),
      ],
    );
  }
}
