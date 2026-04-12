import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:likha/domain/grading/entities/sf9.dart';

class Sf9PrintService {
  static Future<void> printSf9(
    BuildContext context,
    Sf9Response sf9,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final schoolName = prefs.getString('school_name') ?? '';
    final schoolYear = prefs.getString('school_year') ?? '';

    await Printing.layoutPdf(
      onLayout: (format) async {
        final doc = pw.Document();

        doc.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            header: (context) => _buildHeader(
              schoolName: schoolName,
              schoolYear: schoolYear,
              studentName: sf9.studentName,
              gradeLevel: sf9.gradeLevel,
              section: sf9.section,
            ),
            build: (context) => [
              pw.SizedBox(height: 16),
              _buildGradeTable(sf9.subjects, sf9.generalAverage),
            ],
          ),
        );

        return doc.save();
      },
    );
  }

  static pw.Widget _buildHeader({
    required String schoolName,
    required String schoolYear,
    required String studentName,
    String? gradeLevel,
    String? section,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Learner\'s Progress Report Card (SF9)',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (schoolName.isNotEmpty)
          pw.Text(
            schoolName,
            style: const pw.TextStyle(fontSize: 11),
          ),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                'Student: $studentName',
                style: const pw.TextStyle(fontSize: 11),
              ),
            ),
            if (gradeLevel != null)
              pw.Text(
                'Grade: $gradeLevel',
                style: const pw.TextStyle(fontSize: 11),
              ),
          ],
        ),
        pw.Row(
          children: [
            if (section != null)
              pw.Expanded(
                child: pw.Text(
                  'Section: $section',
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ),
            if (schoolYear.isNotEmpty)
              pw.Text(
                'S.Y. $schoolYear',
                style: const pw.TextStyle(fontSize: 11),
              ),
          ],
        ),
        pw.Divider(),
      ],
    );
  }

  static pw.Widget _buildGradeTable(
    List<Sf9SubjectRow> subjects,
    Sf9QuarterlyAverages? generalAverage,
  ) {
    const headerStyle = pw.TextStyle(fontSize: 10);
    const cellStyle = pw.TextStyle(fontSize: 10);
    const boldStyle = pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);

    String gradeText(int? grade) => grade?.toString() ?? '--';

    final rows = <pw.TableRow>[
      // Header
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          _tableCell('Subject', headerStyle, bold: true),
          _tableCell('Q1', headerStyle, center: true, bold: true),
          _tableCell('Q2', headerStyle, center: true, bold: true),
          _tableCell('Q3', headerStyle, center: true, bold: true),
          _tableCell('Q4', headerStyle, center: true, bold: true),
          _tableCell('Final', headerStyle, center: true, bold: true),
          _tableCell('Descriptor', headerStyle, center: true, bold: true),
        ],
      ),
      // Subject rows
      ...subjects.map((subject) => pw.TableRow(
            children: [
              _tableCell(subject.classTitle, cellStyle),
              _tableCell(gradeText(subject.q1), cellStyle, center: true),
              _tableCell(gradeText(subject.q2), cellStyle, center: true),
              _tableCell(gradeText(subject.q3), cellStyle, center: true),
              _tableCell(gradeText(subject.q4), cellStyle, center: true),
              _tableCell(gradeText(subject.finalGrade), cellStyle,
                  center: true),
              _tableCell(subject.descriptor ?? '--', cellStyle,
                  center: true),
            ],
          )),
    ];

    // General Average row
    if (generalAverage != null) {
      rows.add(pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
        children: [
          _tableCell('General Average', boldStyle, bold: true),
          _tableCell(gradeText(generalAverage.q1), boldStyle,
              center: true, bold: true),
          _tableCell(gradeText(generalAverage.q2), boldStyle,
              center: true, bold: true),
          _tableCell(gradeText(generalAverage.q3), boldStyle,
              center: true, bold: true),
          _tableCell(gradeText(generalAverage.q4), boldStyle,
              center: true, bold: true),
          _tableCell(gradeText(generalAverage.finalAverage), boldStyle,
              center: true, bold: true),
          _tableCell(generalAverage.descriptor ?? '--', boldStyle,
              center: true),
        ],
      ));
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
        5: const pw.FlexColumnWidth(1),
        6: const pw.FlexColumnWidth(2),
      },
      children: rows,
    );
  }

  static pw.Widget _tableCell(
    String text,
    pw.TextStyle style, {
    bool center = false,
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(
        text,
        style: bold
            ? pw.TextStyle(
                fontSize: style.fontSize,
                fontWeight: pw.FontWeight.bold,
              )
            : style,
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }
}
