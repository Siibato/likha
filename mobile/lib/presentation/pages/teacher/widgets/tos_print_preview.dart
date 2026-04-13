import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';

class TosPrintService {
  static Future<void> printTos(
    BuildContext context,
    TableOfSpecifications tos,
    List<TosCompetency> competencies,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final schoolName = prefs.getString('school_name') ?? '';
    final region = prefs.getString('school_region') ?? '';
    final division = prefs.getString('school_division') ?? '';
    final schoolYear = prefs.getString('school_year') ?? '';

    final totalDays = competencies.fold<int>(0, (s, c) => s + c.timeUnitsTaught);

    final cogHeaders = tos.classificationMode == 'blooms'
        ? ['R', 'U', 'Ap', 'An', 'E', 'C']
        : ['Easy', 'Avg', 'Diff'];

    await Printing.layoutPdf(
      onLayout: (format) async {
        final doc = pw.Document();

        doc.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4.landscape,
            margin: const pw.EdgeInsets.all(30),
            header: (context) => _buildHeader(
              schoolName: schoolName,
              region: region,
              division: division,
              schoolYear: schoolYear,
              title: tos.title,
              gradingPeriodNumber: tos.gradingPeriodNumber,
              mode: tos.classificationMode,
            ),
            footer: (context) => _buildFooter(context),
            build: (context) => [
              _buildGrid(competencies, cogHeaders, totalDays, tos),
              pw.SizedBox(height: 24),
              _buildSignatures(),
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
    required int gradingPeriodNumber,
    required String mode,
  }) {
    final modeLabel = mode == 'blooms' ? "Bloom's Taxonomy" : 'Difficulty Level';
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (region.isNotEmpty) pw.Text('Republic of the Philippines', style: const pw.TextStyle(fontSize: 8)),
        if (region.isNotEmpty) pw.Text('Department of Education', style: const pw.TextStyle(fontSize: 8)),
        if (region.isNotEmpty) pw.Text(region, style: const pw.TextStyle(fontSize: 8)),
        if (division.isNotEmpty) pw.Text(division, style: const pw.TextStyle(fontSize: 8)),
        if (schoolName.isNotEmpty)
          pw.Text(schoolName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text('TABLE OF SPECIFICATIONS', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text('$title | Quarter $gradingPeriodNumber | $modeLabel', style: const pw.TextStyle(fontSize: 9)),
        if (schoolYear.isNotEmpty) pw.Text('School Year: $schoolYear', style: const pw.TextStyle(fontSize: 8)),
        pw.SizedBox(height: 8),
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 4),
      ],
    );
  }

  static pw.Widget _buildGrid(
    List<TosCompetency> competencies,
    List<String> cogHeaders,
    int totalDays,
    TableOfSpecifications tos,
  ) {
    final headers = [
      'Competency',
      'Days',
      '%',
      ...cogHeaders,
      'Total',
    ];

    final isBloomsMode = tos.classificationMode == 'blooms';
    int gridActualTotal = 0;

    final data = competencies.map((c) {
      final weight = totalDays > 0 ? ((c.timeUnitsTaught as int) / totalDays * 100) : 0.0;
      final targetItems =
          totalDays > 0 ? (weight * tos.totalItems / 100).round() : 0;

      final easyItems = c.easyCount ??
          (targetItems * tos.easyPercentage / 100).round();
      final mediumItems = c.mediumCount ??
          (targetItems * tos.mediumPercentage / 100).round();
      final hardItems = c.hardCount ??
          (targetItems * tos.hardPercentage / 100).round();
      final rowTotal = easyItems + mediumItems + hardItems;
      gridActualTotal += rowTotal;

      final List<String> cogCells;
      if (!isBloomsMode) {
        cogCells = ['$easyItems', '$mediumItems', '$hardItems'];
      } else {
        // Bloom's: split easy→R/U, medium→Ap/An, hard→E/C
        final totalRU =
            tos.rememberingPercentage + tos.understandingPercentage;
        final rRatio =
            totalRU > 0 ? tos.rememberingPercentage / totalRU : 0.5;
        final r = (easyItems * rRatio).round();
        final u = easyItems - r;

        final totalApAn = tos.applyingPercentage + tos.analyzingPercentage;
        final apRatio =
            totalApAn > 0 ? tos.applyingPercentage / totalApAn : 0.5;
        final ap = (mediumItems * apRatio).round();
        final an = mediumItems - ap;

        final totalEC =
            tos.evaluatingPercentage + tos.creatingPercentage;
        final eRatio =
            totalEC > 0 ? tos.evaluatingPercentage / totalEC : 0.5;
        final e = (hardItems * eRatio).round();
        final cr = hardItems - e;

        cogCells = ['$r', '$u', '$ap', '$an', '$e', '$cr'];
      }

      return [
        c.competencyCode != null
            ? '${c.competencyCode} - ${c.competencyText}'
            : c.competencyText,
        '${c.timeUnitsTaught as int}',
        '${weight.toStringAsFixed(1)}%',
        ...cogCells,
        '$rowTotal',
      ];
    }).toList();

    // Totals row — show actual sum, same as the on-screen grid
    data.add([
      'TOTAL',
      '$totalDays',
      '100%',
      ...cogHeaders.map((_) => '-'),
      '$gridActualTotal',
    ]);

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 7),
      headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF0F0F0)),
      border: pw.TableBorder.all(width: 0.5),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        for (int i = 1; i < headers.length; i++) i: pw.Alignment.center,
      },
    );
  }

  static pw.Widget _buildSignatures() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        _signatureLine('Prepared by:'),
        _signatureLine('Checked by:'),
        _signatureLine('Noted by:'),
      ],
    );
  }

  static pw.Widget _signatureLine(String label) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
        pw.SizedBox(height: 24),
        pw.Container(
          width: 140,
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text('Signature over Printed Name', style: const pw.TextStyle(fontSize: 7)),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 0.5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Generated by Likha LMS', style: const pw.TextStyle(fontSize: 7)),
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 7)),
          ],
        ),
      ],
    );
  }
}
