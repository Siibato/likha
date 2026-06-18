import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:likha/domain/grading/entities/sf9.dart';

pw.Widget buildSf9Page2({
  required Sf9Response sf9,
  Uint8List? sealBytes,
}) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      // Left: Report on Learning Progress and Achievement
      pw.Expanded(
        flex: 3,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'REPORT ON LEARNING PROGRESS AND ACHIEVEMENT',
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            _buildLearningProgressTable(sf9),
            pw.SizedBox(height: 8),
            _buildGradingScaleLegend(),
          ],
        ),
      ),
      pw.SizedBox(width: 12),
      // Right: Report on Learner's Observed Values
      pw.Expanded(
        flex: 2,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              "REPORT ON LEARNER'S OBSERVED VALUES",
              style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            _buildCoreValuesTable(),
          ],
        ),
      ),
    ],
  );
}

pw.Widget _buildLearningProgressTable(Sf9Response sf9) {
  pw.Widget headerCell(String text) => pw.Container(
        height: 22,
        padding: const pw.EdgeInsets.all(2),
        child: pw.Center(
          child: pw.Text(
            text,
            style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
        ),
      );

  pw.Widget dataCell(String text, {bool bold = false}) => pw.Container(
        height: 18,
        padding: const pw.EdgeInsets.all(2),
        child: pw.Center(
          child: pw.Text(
            text,
            style: pw.TextStyle(fontSize: 6, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
            textAlign: pw.TextAlign.center,
          ),
        ),
      );

  pw.Widget gradeCell(int? grade, {bool bold = false}) => dataCell(
        grade?.toString() ?? '',
        bold: bold,
      );

  pw.Widget passFail(int? grade) => dataCell(
        grade == null ? '' : (grade >= 75 ? 'Passed' : 'Failed'),
      );

  final rows = <pw.TableRow>[
    pw.TableRow(
      children: [
        headerCell('Learning Areas'),
        headerCell('Q1'),
        headerCell('Q2'),
        headerCell('Q3'),
        headerCell('Q4'),
        headerCell('Final\nRating'),
        headerCell('Remarks'),
      ],
    ),
    ...sf9.subjects.map((s) => pw.TableRow(
          children: [
            dataCell(s.classTitle),
            gradeCell(s.q1),
            gradeCell(s.q2),
            gradeCell(s.q3),
            gradeCell(s.q4),
            gradeCell(s.finalGrade, bold: true),
            passFail(s.finalGrade),
          ],
        )),
  ];

  if (sf9.generalAverage != null) {
    final ga = sf9.generalAverage!;
    rows.add(pw.TableRow(
      children: [
        dataCell('General Average', bold: true),
        gradeCell(ga.q1, bold: true),
        gradeCell(ga.q2, bold: true),
        gradeCell(ga.q3, bold: true),
        gradeCell(ga.q4, bold: true),
        gradeCell(ga.finalAverage, bold: true),
        passFail(ga.finalAverage),
      ],
    ));
  }

  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
    columnWidths: const {
      0: pw.FixedColumnWidth(100),
      1: pw.FixedColumnWidth(32),
      2: pw.FixedColumnWidth(32),
      3: pw.FixedColumnWidth(32),
      4: pw.FixedColumnWidth(32),
      5: pw.FixedColumnWidth(36),
      6: pw.FixedColumnWidth(40),
    },
    children: rows,
  );
}

pw.Widget _buildGradingScaleLegend() {
  final legendData = [
    ['90-94', 'Outstanding', 'Passed'],
    ['85-89', 'Very Satisfactory', 'Passed'],
    ['80-84', 'Satisfactory', 'Passed'],
    ['75-79', 'Fair', 'Passed'],
    ['Below 75', 'Did Not Meet Expectations', 'Failed'],
  ];

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
        columnWidths: const {
          0: pw.FixedColumnWidth(50),
          1: pw.FixedColumnWidth(80),
          2: pw.FixedColumnWidth(50),
        },
        children: [
          pw.TableRow(
            children: [
              _legendHeader('Range'),
              _legendHeader('Descriptor'),
              _legendHeader('Remarks'),
            ],
          ),
          ...legendData.map((row) => pw.TableRow(
                children: row.map((c) => _legendCell(c)).toList(),
              )),
        ],
      ),
    ],
  );
}

pw.Widget _legendHeader(String text) => pw.Container(
      height: 16,
      padding: const pw.EdgeInsets.all(2),
      child: pw.Center(
        child: pw.Text(text, style: pw.TextStyle(fontSize: 5, fontWeight: pw.FontWeight.bold)),
      ),
    );

pw.Widget _legendCell(String text) => pw.Container(
      height: 14,
      padding: const pw.EdgeInsets.all(2),
      child: pw.Center(
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 5)),
      ),
    );

pw.Widget _buildCoreValuesTable() {
  final coreValues = [
    ('Maka-Diyos', [
      "Expresses one's spiritual beliefs while respecting those of others",
      'Shows adherence to ethical principles by upholding truth and justice at all times',
    ]),
    ('Makatao', [
      'Demonstrates pride in being a Filipino without looking down on others',
      'Listens attentively and responds appropriately to the opinions of others',
    ]),
    ('Maka-Kalikasan', [
      'Shows care and concern for the environment',
      'Demonstrates resourcefulness and creativity in solving problems',
    ]),
    ('Maka-bansa', [
      'Demonstrates pride in being a Filipino without looking down on others',
      'Shows commitment to the ideals of democracy and nationalism',
    ]),
  ];

  final rows = <pw.TableRow>[
    pw.TableRow(
      children: [
        _cvHeader('Core Values'),
        _cvHeader('Behavior Statements'),
        _cvHeader('Q1'),
        _cvHeader('Q2'),
        _cvHeader('Q3'),
        _cvHeader('Q4'),
      ],
    ),
  ];

  for (final cv in coreValues) {
    for (int i = 0; i < cv.$2.length; i++) {
      rows.add(pw.TableRow(
        children: [
          i == 0 ? _cvCell(cv.$1, bold: true) : _cvCell(''),
          _cvCell(cv.$2[i], align: pw.Alignment.centerLeft),
          _cvCell(''),
          _cvCell(''),
          _cvCell(''),
          _cvCell(''),
        ],
      ));
    }
  }

  rows.add(pw.TableRow(
    children: [
      pw.Container(height: 8, padding: const pw.EdgeInsets.all(1), child: pw.Text('Marking: AO - Always Observed | SO - Sometimes Observed | RO - Rarely Observed | NO - Not Observed', style: const pw.TextStyle(fontSize: 4))),
      pw.Container(height: 8),
      pw.Container(height: 8),
      pw.Container(height: 8),
      pw.Container(height: 8),
      pw.Container(height: 8),
    ],
  ));

  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
    columnWidths: const {
      0: pw.FixedColumnWidth(45),
      1: pw.FixedColumnWidth(90),
      2: pw.FixedColumnWidth(18),
      3: pw.FixedColumnWidth(18),
      4: pw.FixedColumnWidth(18),
      5: pw.FixedColumnWidth(18),
    },
    children: rows,
  );
}

pw.Widget _cvHeader(String text) => pw.Container(
      height: 18,
      padding: const pw.EdgeInsets.all(2),
      child: pw.Center(
        child: pw.Text(text, style: pw.TextStyle(fontSize: 5, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
      ),
    );

pw.Widget _cvCell(String text, {bool bold = false, pw.Alignment align = pw.Alignment.center}) => pw.Container(
      height: 16,
      padding: const pw.EdgeInsets.all(1),
      child: pw.Align(
        alignment: align,
        child: pw.Text(text, style: pw.TextStyle(fontSize: 4, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ),
    );
