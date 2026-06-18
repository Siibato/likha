import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:likha/domain/grading/entities/sf9.dart';
import 'package:likha/domain/setup/entities/school_settings.dart';

pw.Widget buildSf9Page1({
  required Sf9Response sf9,
  required SchoolSettings? schoolSettings,
  required String studentName,
  Uint8List? sealBytes,
}) {
  final schoolName = schoolSettings?.schoolName ?? '';
  final region = schoolSettings?.schoolRegion ?? '';
  final division = schoolSettings?.schoolDivision ?? '';
  final district = schoolSettings?.schoolDistrict ?? '';
  final schoolYear = sf9.schoolYear ?? schoolSettings?.schoolYear ?? '';
  final schoolId = schoolSettings?.schoolCode ?? '';

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      // ── Top row: SF9 label + DepEd header + Student info ──
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left: SF9-SHS label + LRN boxes
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'SF9-SHS',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text('LRN', style: const pw.TextStyle(fontSize: 7)),
              pw.SizedBox(height: 2),
              pw.Row(
                children: List.generate(12, (i) {
                  final lrn = sf9.lrn;
                  final ch = lrn != null && i < lrn.length ? lrn[i] : '';
                  return pw.Container(
                    width: 14,
                    height: 14,
                    margin: const pw.EdgeInsets.only(right: 1),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.black, width: 0.5),
                    ),
                    child: pw.Center(
                      child: pw.Text(ch, style: const pw.TextStyle(fontSize: 6)),
                    ),
                  );
                }),
              ),
            ],
          ),
          pw.SizedBox(width: 12),
          // Center: DepEd seal + header
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (sealBytes != null)
                  pw.Image(pw.MemoryImage(sealBytes), width: 45, height: 45)
                else
                  pw.Container(width: 45, height: 45),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Republic of the Philippines',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'DEPARTMENT OF EDUCATION',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                _metaLine('Region', region),
                _metaLine('Division', division),
                if (district.isNotEmpty) _metaLine('District', district),
                _metaLine('School Name', schoolName),
                _metaLine('School ID', schoolId),
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          // Right: Student info block
          pw.SizedBox(
            width: 180,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _infoField('Name (Last, First, Middle)', studentName),
                pw.SizedBox(height: 3),
                _infoField('Age', sf9.age?.toString() ?? ''),
                pw.SizedBox(height: 3),
                _infoField('Sex', sf9.sex ?? ''),
                pw.SizedBox(height: 3),
                _infoField('Grade Level', sf9.gradeLevel ?? ''),
                pw.SizedBox(height: 3),
                _infoField('Section', sf9.section ?? ''),
                pw.SizedBox(height: 3),
                _infoField('Curriculum', sf9.curriculum ?? ''),
                pw.SizedBox(height: 3),
                _infoField('School Year', schoolYear),
                pw.SizedBox(height: 3),
                _infoField('Track/Strand', sf9.trackStrand ?? ''),
              ],
            ),
          ),
        ],
      ),

      pw.SizedBox(height: 16),

      // ── Report on Attendance ──
      pw.Text(
        'REPORT ON ATTENDANCE',
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 4),
      _buildAttendanceTable(),

      pw.SizedBox(height: 16),

      // ── Parent's/Guardian's Signature ──
      pw.Text(
        "Parent's/Guardian's Signature",
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 8),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _signatureLine('1st Quarter'),
          _signatureLine('2nd Quarter'),
          _signatureLine('3rd Quarter'),
          _signatureLine('4th Quarter'),
        ],
      ),

      pw.SizedBox(height: 20),

      // ── Certificate of Transfer ──
      pw.Text(
        'CERTIFICATE OF TRANSFER',
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 6),
      _infoField('Admitted to Grade', ''),
      pw.SizedBox(height: 4),
      _infoField('School', ''),
      pw.SizedBox(height: 4),
      _infoField('Date', ''),
      pw.SizedBox(height: 4),
      _infoField('Signature of School Head', ''),

      pw.SizedBox(height: 16),

      // ── Cancellation of Eligibility to Transfer ──
      pw.Text(
        'CANCELLATION OF ELIGIBILITY TO TRANSFER',
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 4),
      _infoField('Eligibility cancelled on', ''),
      pw.SizedBox(height: 4),
      _infoField('Reason', ''),
      pw.SizedBox(height: 4),
      _infoField('Signature of School Head', ''),

      pw.SizedBox(height: 16),

      // ── Dear Parent/Guardian letter ──
      pw.Text(
        'Dear Parent/Guardian:',
        style: const pw.TextStyle(fontSize: 8),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        'Please be informed that the enclosed report card shows the scholastic '
        'standing of your child/ward in this school. You are hereby requested '
        'to examine this report carefully. If you have any questions regarding '
        'the report, please see the class adviser.',
        style: const pw.TextStyle(fontSize: 7),
        textAlign: pw.TextAlign.justify,
      ),
      pw.SizedBox(height: 8),
      _infoField('Class Adviser', ''),
    ],
  );
}

pw.Widget _metaLine(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          value.isEmpty ? '_______' : value,
          style: const pw.TextStyle(fontSize: 7),
        ),
      ],
    ),
  );
}

pw.Widget _infoField(String label, String value) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        '$label: ',
        style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
      ),
      pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 1),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
            ),
          ),
          child: pw.Text(
            value.isEmpty ? ' ' : value,
            style: const pw.TextStyle(fontSize: 7),
          ),
        ),
      ),
    ],
  );
}

pw.Widget _buildAttendanceTable() {
  final months = [
    'June', 'July', 'August', 'September', 'October',
    'November', 'December', 'January', 'February',
    'March', 'April', 'TOTAL'
  ];
  final rows = ['No. of School Days', 'Days Present', 'Days Absent'];

  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
    columnWidths: {
      0: const pw.FixedColumnWidth(90),
      ...Map.fromIterables(
        List.generate(months.length, (i) => i + 1),
        List.generate(months.length, (_) => const pw.FixedColumnWidth(32)),
      ),
    },
    children: [
      pw.TableRow(
        children: [
          pw.Container(
            height: 20,
            padding: const pw.EdgeInsets.all(2),
            child: pw.Center(
              child: pw.Text('Month', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
            ),
          ),
          ...months.map((m) => pw.Container(
                height: 20,
                padding: const pw.EdgeInsets.all(2),
                child: pw.Center(
                  child: pw.Text(m, style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold)),
                ),
              )),
        ],
      ),
      ...rows.map((rowLabel) => pw.TableRow(
            children: [
              pw.Container(
                height: 18,
                padding: const pw.EdgeInsets.all(2),
                child: pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(rowLabel, style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold)),
                ),
              ),
              ...List.generate(months.length, (_) => pw.Container(height: 18)),
            ],
          )),
    ],
  );
}

pw.Widget _signatureLine(String label) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.Container(
        width: 100,
        height: 24,
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
          ),
        ),
      ),
      pw.SizedBox(height: 2),
      pw.Text(label, style: const pw.TextStyle(fontSize: 7)),
    ],
  );
}
