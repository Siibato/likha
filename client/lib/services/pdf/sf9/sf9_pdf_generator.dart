import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_saver/file_saver.dart';
import 'package:likha/core/logging/service_logger.dart';
import 'package:likha/domain/grading/entities/sf9.dart';
import 'package:likha/domain/setup/entities/school_settings.dart';
import 'sf9_page1.dart';
import 'sf9_page2.dart';

class Sf9PdfGenerator {
  Future<void> generatePdf({
    required Sf9Response sf9,
    required SchoolSettings? schoolSettings,
    required String studentName,
  }) async {
    ServiceLogger.instance.log('Sf9PdfGenerator: Starting PDF generation for $studentName');

    Uint8List? sealBytes;
    try {
      final sealData = await rootBundle.load('assets/images/deped_seal.png');
      sealBytes = sealData.buffer.asUint8List();
    } catch (_) {
      ServiceLogger.instance.warn('Sf9PdfGenerator: DepEd seal not available');
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return buildSf9Page1(
            sf9: sf9,
            schoolSettings: schoolSettings,
            studentName: studentName,
            sealBytes: sealBytes,
          );
        },
      ),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return buildSf9Page2(
            sf9: sf9,
            sealBytes: sealBytes,
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final fileName = 'SF9_${studentName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';

    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: Uint8List.fromList(bytes),
      ext: '.pdf',
      mimeType: MimeType.pdf,
    );

    ServiceLogger.instance.log('Sf9PdfGenerator: PDF saved as $fileName');
  }
}

final sf9PdfGeneratorProvider = Provider<Sf9PdfGenerator>((ref) {
  return Sf9PdfGenerator();
});
