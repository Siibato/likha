import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:likha/core/logging/service_logger.dart';
import 'package:likha/services/grade_export_service.dart';

pw.Widget buildDepEdHeader(GradeExportContext ctx,
    {Uint8List? sealBytes, Uint8List? logoBytes}) {
  ServiceLogger.instance.log('buildDepEdHeader: Rendering header with values:');
  ServiceLogger.instance.log('  - REGION: "${ctx.region ?? ""}"');
  ServiceLogger.instance.log('  - DIVISION: "${ctx.division ?? ""}"');
  ServiceLogger.instance.log('  - DISTRICT: "${ctx.district ?? ""}"');
  ServiceLogger.instance.log('  - SCHOOL NAME: "${ctx.schoolName ?? ""}"');
  ServiceLogger.instance.log('  - SCHOOL ID: "${ctx.schoolId ?? ""}"');
  ServiceLogger.instance.log('  - SCHOOL YEAR: "${ctx.schoolYear ?? ""}"');
  ServiceLogger.instance.log('  - GRADE & SECTION: "${ctx.gradeLevel ?? ""} ${ctx.section ?? ctx.className}".trim()');
  ServiceLogger.instance.log('  - TEACHER: "${ctx.teacherName ?? ""}"');
  ServiceLogger.instance.log('  - SUBJECT: "${ctx.subject ?? ""}"');
  
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      // Logo row
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (sealBytes != null)
            pw.Image(
              pw.MemoryImage(sealBytes),
              width: 50,
              height: 50,
            )
          else
            pw.Container(width: 50, height: 50),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'Class Record',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.Text(
                  '(Pursuant to DepEd Order 8 series of 2015)',
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
          if (logoBytes != null)
            pw.Image(
              pw.MemoryImage(logoBytes),
              width: 80,
              height: 40,
            )
          else
            pw.Container(width: 80, height: 40),
        ],
      ),
      pw.SizedBox(height: 6),
      // Metadata row 1
      pw.Row(
        children: [
          _metaField('REGION', ctx.region ?? '', flex: 1),
          pw.SizedBox(width: 8),
          _metaField('DIVISION', ctx.division ?? '', flex: 1),
          pw.SizedBox(width: 8),
          _metaField('DISTRICT', ctx.district ?? '', flex: 1),
        ],
      ),
      pw.SizedBox(height: 4),
      // Metadata row 2
      pw.Row(
        children: [
          _metaField('SCHOOL NAME', ctx.schoolName ?? '', flex: 3),
          pw.SizedBox(width: 8),
          _metaField('SCHOOL ID', ctx.schoolId ?? '', flex: 1),
          pw.SizedBox(width: 8),
          _metaField('SCHOOL YEAR', ctx.schoolYear ?? '', flex: 1),
        ],
      ),
      pw.SizedBox(height: 4),
      // Class info row
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: pw.Text(
              ctx.quarterLabel,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            flex: 2,
            child: _infoRow(
              'GRADE & SECTION:',
              '${ctx.gradeLevel ?? ''} ${ctx.section ?? ctx.className}'.trim(),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            flex: 2,
            child: _infoRow('TEACHER:', ctx.teacherName ?? ''),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            flex: 2,
            child: _infoRow('SUBJECT:', ctx.subject ?? ''),
          ),
          pw.SizedBox(width: 8),
          pw.Container(
            width: 80,
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey300,
              border: pw.Border.all(color: PdfColors.black, width: 0.5),
            ),
            child: pw.Center(
              child: pw.Text(
                ctx.quarterLabel,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

pw.Widget _metaField(String label, String value, {int flex = 1}) {
  return pw.Expanded(
    flex: flex,
    child: pw.Row(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(width: 4),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 0.5),
            ),
            child: pw.Text(
              value.isEmpty ? ' ' : value,
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
        ),
      ],
    ),
  );
}

pw.Widget _infoRow(String label, String value) {
  return pw.Row(
    children: [
      pw.Text(
        label,
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.SizedBox(width: 4),
      pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
            ),
          ),
          child: pw.Text(
            value.isEmpty ? ' ' : value,
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
      ),
    ],
  );
}
