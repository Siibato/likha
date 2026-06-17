import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_saver/file_saver.dart';
import 'package:likha/services/excel/excel_header_builder.dart';
import 'package:likha/services/excel/excel_table_builder.dart';
import 'package:likha/services/grade_export_service.dart';

class GradeExcelGenerator {
  Future<void> generateExcel(GradeExportContext ctx) async {
    final excel = Excel.createExcel();
    final sheet = excel['Class Record'];

    _setColumnWidths(sheet, ctx);

    final headerBuilder = ExcelHeaderBuilder();
    final tableStartRow = headerBuilder.build(sheet, ctx);

    final tableBuilder = ExcelTableBuilder();
    tableBuilder.build(sheet, ctx, tableStartRow);

    final bytes = excel.encode();
    if (bytes == null) throw Exception('Failed to encode Excel file');

    final fileName =
        '${ctx.className}_Q${ctx.quarter}_Grades_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: Uint8List.fromList(bytes),
      ext: '.xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }

  void _setColumnWidths(Sheet sheet, GradeExportContext ctx) {
    final ww = ctx.ww;
    final pt = ctx.pt;
    final qa = ctx.qa;

    final wwCols = ww.items.isNotEmpty ? ww.items.length + 3 : 0;
    final ptCols = pt.items.isNotEmpty ? pt.items.length + 3 : 0;
    final qaCols = qa.items.isNotEmpty ? qa.items.length + 3 : 0;

    var col = 0;
    sheet.setColumnWidth(col++, 22); // Names
    for (int i = 0; i < wwCols; i++) {
      sheet.setColumnWidth(col++, i < ww.items.length ? 5 : 7);
    }
    for (int i = 0; i < ptCols; i++) {
      sheet.setColumnWidth(col++, i < pt.items.length ? 5 : 7);
    }
    for (int i = 0; i < qaCols; i++) {
      sheet.setColumnWidth(col++, i < qa.items.length ? 5 : 7);
    }
    sheet.setColumnWidth(col++, 9);  // Initial Grade
    sheet.setColumnWidth(col++, 10); // Quarterly Grade
  }
}

final gradeExcelGeneratorProvider = Provider<GradeExcelGenerator>((ref) {
  return GradeExcelGenerator();
});
