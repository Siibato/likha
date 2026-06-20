import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_saver/file_saver.dart';
import 'package:likha/core/logging/service_logger.dart';
import 'package:likha/services/grade_export_service.dart';
import 'package:likha/services/pdf/deped_pdf_header.dart';
import 'package:likha/services/pdf/deped_pdf_table.dart';

/// Service for generating DepEd-compliant PDF grade reports
class GradePdfGenerator {
  Future<void> generatePdf(GradeExportContext ctx) async {
    ServiceLogger.instance.log('generatePdf: Starting PDF generation with ${ctx.studentRows.length} students');
    ServiceLogger.instance.log('generatePdf: Context values - schoolName="${ctx.schoolName}", region="${ctx.region}", division="${ctx.division}", schoolId="${ctx.schoolId}", schoolYear="${ctx.schoolYear}"');
    
    // Load DepEd images from assets
    Uint8List? sealBytes;
    Uint8List? logoBytes;
    try {
      final sealData = await rootBundle.load('assets/images/deped_seal.png');
      sealBytes = sealData.buffer.asUint8List();
      ServiceLogger.instance.log('generatePdf: DepEd seal loaded successfully');
    } catch (_) {
      ServiceLogger.instance.warn('generatePdf: DepEd seal not available');
      // Seal not available
    }
    try {
      final logoData = await rootBundle.load('assets/images/deped_logo.png');
      logoBytes = logoData.buffer.asUint8List();
      ServiceLogger.instance.log('generatePdf: DepEd logo loaded successfully');
    } catch (_) {
      ServiceLogger.instance.warn('generatePdf: DepEd logo not available');
      // Logo not available
    }

    final pdf = pw.Document();

    // Calculate pagination: 20 students per page for A4 landscape
    const studentsPerPage = 20;
    final totalStudents = ctx.studentRows.length;
    final totalPages = (totalStudents + studentsPerPage - 1) ~/ studentsPerPage;

    ServiceLogger.instance.log('generatePdf: Creating $totalPages pages for $totalStudents students');

    for (int page = 0; page < totalPages; page++) {
      final startIdx = page * studentsPerPage;
      final endIdx = (startIdx + studentsPerPage).clamp(0, totalStudents);

      ServiceLogger.instance.log('generatePdf: Building page ${page + 1}/$totalPages (students $startIdx-$endIdx)');

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                buildDepEdHeader(ctx, sealBytes: sealBytes, logoBytes: logoBytes),
                pw.SizedBox(height: 8),
                pw.Expanded(
                  child: pw.Center(
                    child: buildGradeTable(ctx, startIdx: startIdx, endIdx: endIdx),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    ServiceLogger.instance.log('generatePdf: Saving PDF to file');
    final bytes = await pdf.save();
    final fileName =
        '${ctx.className}_Q${ctx.quarter}_Grades_${DateTime.now().millisecondsSinceEpoch}.pdf';

    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: Uint8List.fromList(bytes),
      ext: '.pdf',
      mimeType: MimeType.pdf,
    );
    
    ServiceLogger.instance.log('generatePdf: PDF file saved successfully as $fileName');
  }
}

/// Provider for GradePdfGenerator
final gradePdfGeneratorProvider = Provider<GradePdfGenerator>((ref) {
  return GradePdfGenerator();
});
