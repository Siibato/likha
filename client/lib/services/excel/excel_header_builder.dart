import 'package:excel/excel.dart';
import 'package:likha/services/excel/excel_style_utils.dart';
import 'package:likha/services/grade_export_service.dart';

class ExcelHeaderBuilder {
  int build(Sheet sheet, GradeExportContext ctx) {
    final totalCols = _totalColumns(ctx);
    var row = 0;

    // Title row
    ExcelStyleUtils.setCell(sheet, row, 0, 'Class Record',
        bold: true, fontSize: 16, hAlign: HorizontalAlign.Center);
    ExcelStyleUtils.merge(sheet, row, 0, row, totalCols - 1);
    row++;

    // Subtitle row
    ExcelStyleUtils.setCell(sheet, row, 0, '(Pursuant to DepEd Order 8 series of 2015)',
        fontSize: 8, hAlign: HorizontalAlign.Center);
    ExcelStyleUtils.merge(sheet, row, 0, row, totalCols - 1);
    row++;
    row++; // blank separator

    // Metadata row 1: REGION | DIVISION | DISTRICT
    final meta1Spans = _distributeSpans(totalCols, 3);
    var col = 0;
    _metaField(sheet, row, col, meta1Spans[0], 'REGION', ctx.region ?? '');
    col += meta1Spans[0];
    _metaField(sheet, row, col, meta1Spans[1], 'DIVISION', ctx.division ?? '');
    col += meta1Spans[1];
    _metaField(sheet, row, col, meta1Spans[2], 'DISTRICT', '');
    row++;
    row++; // blank separator

    // Metadata row 2: SCHOOL NAME | SCHOOL YEAR (no SCHOOL ID)
    final meta2Spans = _distributeSpans(totalCols, 2);
    col = 0;
    _metaField(sheet, row, col, meta2Spans[0], 'SCHOOL NAME', ctx.schoolName ?? '');
    col += meta2Spans[0];
    _metaField(sheet, row, col, meta2Spans[1], 'SCHOOL YEAR', ctx.schoolYear ?? '');
    row++;
    row++; // blank separator

    // Class info row
    _buildClassInfoRow(sheet, ctx, row, totalCols);
    row++;
    row++; // blank separator

    return row;
  }

  void _metaField(Sheet sheet, int row, int startCol, int span,
      String label, String value) {
    ExcelStyleUtils.setCell(sheet, row, startCol, label,
        bold: true, fontSize: 7);
    final valueCol = startCol + 1;
    final endCol = startCol + span - 1;
    ExcelStyleUtils.setCell(
      sheet, row, valueCol, value.isEmpty ? ' ' : value,
      fontSize: 8,
      allBorders: true,
      hAlign: HorizontalAlign.Center,
    );
    if (endCol > valueCol) {
      ExcelStyleUtils.merge(sheet, row, valueCol, row, endCol);
    }
  }

  void _buildClassInfoRow(Sheet sheet, GradeExportContext ctx, int row, int totalCols) {
    // Minimum columns needed: quarter(1) + gs_label(1) + gs_value(2) +
    //   teacher_label(1) + teacher_value(2) + subject_label(1) + subject_value(2) + box(1) = 11
    int gsValueSpan = 2;
    int teacherValueSpan = 2;
    int subjectValueSpan = 2;
    int minCols = 1 + 1 + gsValueSpan + 1 + teacherValueSpan + 1 + subjectValueSpan + 1;

    if (totalCols < minCols) {
      final deficit = minCols - totalCols;
      // Shrink value spans proportionally
      for (int i = 0; i < deficit; i++) {
        if (gsValueSpan > 1) {
          gsValueSpan--;
        } else if (teacherValueSpan > 1) {
          teacherValueSpan--;
        } else if (subjectValueSpan > 1) {
          subjectValueSpan--;
        }
      }
    }

    var col = 0;

    // Quarter label
    ExcelStyleUtils.setCell(sheet, row, col, ctx.quarterLabel,
        bold: true, fontSize: 8);
    col += 1;

    // GRADE & SECTION
    ExcelStyleUtils.setCell(sheet, row, col, 'GRADE & SECTION:',
        bold: true, fontSize: 7);
    col += 1;
    final gsValue = '${ctx.gradeLevel ?? ''} ${ctx.section ?? ctx.className}'.trim();
    ExcelStyleUtils.setCell(sheet, row, col, gsValue.isEmpty ? ' ' : gsValue,
        fontSize: 8, underline: true);
    if (gsValueSpan > 1) {
      ExcelStyleUtils.merge(sheet, row, col, row, col + gsValueSpan - 1);
    }
    col += gsValueSpan;

    // TEACHER
    ExcelStyleUtils.setCell(sheet, row, col, 'TEACHER:',
        bold: true, fontSize: 7);
    col += 1;
    final teacherValue = ctx.teacherName?.isEmpty ?? true ? ' ' : ctx.teacherName!;
    ExcelStyleUtils.setCell(sheet, row, col, teacherValue,
        fontSize: 8, underline: true);
    if (teacherValueSpan > 1) {
      ExcelStyleUtils.merge(sheet, row, col, row, col + teacherValueSpan - 1);
    }
    col += teacherValueSpan;

    // SUBJECT
    ExcelStyleUtils.setCell(sheet, row, col, 'SUBJECT:',
        bold: true, fontSize: 7);
    col += 1;
    final subjectValue = ctx.subject?.isEmpty ?? true ? ' ' : ctx.subject!;
    ExcelStyleUtils.setCell(sheet, row, col, subjectValue,
        fontSize: 8, underline: true);
    if (subjectValueSpan > 1) {
      ExcelStyleUtils.merge(sheet, row, col, row, col + subjectValueSpan - 1);
    }
    col += subjectValueSpan;

    // Quarter box (remaining columns)
    if (col < totalCols) {
      ExcelStyleUtils.setCell(sheet, row, col, ctx.quarterLabel,
          bold: true, fontSize: 9, bgColor: '#D9D9D9',
          hAlign: HorizontalAlign.Center, allBorders: true);
      if (col + 1 < totalCols) {
        ExcelStyleUtils.merge(sheet, row, col, row, totalCols - 1);
      }
    }
  }

  /// Distribute total columns evenly across N fields.
  /// Each field gets 1 column for its label plus a share of the remaining
  /// columns for its value box.
  List<int> _distributeSpans(int totalCols, int fieldCount) {
    final available = totalCols - fieldCount; // columns left for values
    final base = available ~/ fieldCount;
    final extra = available % fieldCount;
    final spans = <int>[];
    for (int i = 0; i < fieldCount; i++) {
      spans.add(1 + base + (i < extra ? 1 : 0));
    }
    return spans;
  }

  static int _totalColumns(GradeExportContext ctx) {
    final wwCols = ctx.ww.items.isNotEmpty ? ctx.ww.items.length + 3 : 0;
    final ptCols = ctx.pt.items.isNotEmpty ? ctx.pt.items.length + 3 : 0;
    final qaCols = ctx.qa.items.isNotEmpty ? ctx.qa.items.length + 3 : 0;
    return 1 + wwCols + ptCols + qaCols + 2;
  }
}
