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

    final totalDays = competencies.fold<int>(0, (s, c) => s + c.daysTaught);

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
              quarter: tos.quarter,
              mode: tos.classificationMode,
            ),
            footer: (context) => _buildFooter(context),
            build: (context) => [
              _buildGrid(competencies, cogHeaders, totalDays, tos.totalItems),
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
    required int quarter,
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
        pw.Text('$title | Quarter $quarter | $modeLabel', style: const pw.TextStyle(fontSize: 9)),
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
    int totalItems,
  ) {
    final headers = [
      'Competency',
      'Days',
      '%',
      ...cogHeaders,
      'Total',
    ];

    final data = competencies.map((c) {
      final weight = totalDays > 0 ? (c.daysTaught / totalDays * 100) : 0.0;
      final target = totalDays > 0 ? (weight * totalItems / 100).round() : 0;
      return [
        c.competencyCode != null ? '${c.competencyCode} - ${c.competencyText}' : c.competencyText,
        '${c.daysTaught}',
        '${weight.toStringAsFixed(1)}%',
        ...cogHeaders.map((_) => ''),
        '$target',
      ];
    }).toList();

    // Totals row
    data.add([
      'TOTAL',
      '$totalDays',
      '100%',
      ...cogHeaders.map((_) => ''),
      '$totalItems',
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
