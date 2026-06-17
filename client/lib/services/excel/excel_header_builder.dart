import 'package:excel/excel.dart';
import 'package:likha/services/excel/excel_style_utils.dart';
import 'package:likha/services/grade_export_service.dart';

class ExcelHeaderBuilder {
  int build(Sheet sheet, GradeExportContext ctx) {
    final totalCols = _totalColumns(ctx);
    var row = 0;

    // Title row
    ExcelStyleUtils.setCell(sheet, row, 0, 'Class Record',
        bold: true, fontSize: 14, hAlign: HorizontalAlign.Center);
    ExcelStyleUtils.merge(sheet, row, 0, row, totalCols - 1);
    row++;

    // Subtitle row
    ExcelStyleUtils.setCell(sheet, row, 0, '(Pursuant to DepEd Order 8 series of 2015)',
        fontSize: 8, hAlign: HorizontalAlign.Center);
    ExcelStyleUtils.merge(sheet, row, 0, row, totalCols - 1);
    row++;
    row++;

    // Metadata row 1: REGION | DIVISION | DISTRICT
    ExcelStyleUtils.setCell(sheet, row, 0, 'REGION:', bold: true, fontSize: 8);
    ExcelStyleUtils.setCell(sheet, row, 1, ctx.region ?? '', fontSize: 8,
        allBorders: true, hAlign: HorizontalAlign.Center);
    ExcelStyleUtils.merge(sheet, row, 1, row, 2);

    ExcelStyleUtils.setCell(sheet, row, 4, 'DIVISION:', bold: true, fontSize: 8);
    ExcelStyleUtils.setCell(sheet, row, 5, ctx.division ?? '', fontSize: 8,
        allBorders: true, hAlign: HorizontalAlign.Center);
    ExcelStyleUtils.merge(sheet, row, 5, row, 6);

    ExcelStyleUtils.setCell(sheet, row, 8, 'DISTRICT:', bold: true, fontSize: 8);
    ExcelStyleUtils.setCell(sheet, row, 9, '', fontSize: 8,
        allBorders: true, hAlign: HorizontalAlign.Center);
    ExcelStyleUtils.merge(sheet, row, 9, row, 10);
    row++;
    row++;

    // Metadata row 2: SCHOOL NAME | SCHOOL ID | SCHOOL YEAR
    ExcelStyleUtils.setCell(sheet, row, 0, 'SCHOOL NAME:', bold: true, fontSize: 8);
    ExcelStyleUtils.setCell(sheet, row, 1, ctx.schoolName ?? '', fontSize: 8,
        allBorders: true);
    ExcelStyleUtils.merge(sheet, row, 1, row, 5);

    ExcelStyleUtils.setCell(sheet, row, 6, 'SCHOOL ID:', bold: true, fontSize: 8);
    ExcelStyleUtils.setCell(sheet, row, 7, ctx.schoolId ?? '', fontSize: 8,
        allBorders: true, hAlign: HorizontalAlign.Center);
    ExcelStyleUtils.merge(sheet, row, 7, row, 8);

    ExcelStyleUtils.setCell(sheet, row, 9, 'SCHOOL YEAR:', bold: true, fontSize: 8);
    ExcelStyleUtils.setCell(sheet, row, 10, ctx.schoolYear ?? '', fontSize: 8,
        allBorders: true, hAlign: HorizontalAlign.Center);
    ExcelStyleUtils.merge(sheet, row, 10, row, 11);
    row++;
    row++;

    // Class info row
    ExcelStyleUtils.setCell(sheet, row, 0, ctx.quarterLabel,
        bold: true, fontSize: 8);
    ExcelStyleUtils.setCell(sheet, row, 2, 'GRADE & SECTION:', bold: true, fontSize: 8);
    ExcelStyleUtils.setCell(sheet, row, 3,
        '${ctx.gradeLevel ?? ''} ${ctx.section ?? ctx.className}'.trim(),
        fontSize: 8, underline: true);
    ExcelStyleUtils.merge(sheet, row, 3, row, 5);

    ExcelStyleUtils.setCell(sheet, row, 6, 'TEACHER:', bold: true, fontSize: 8);
    ExcelStyleUtils.setCell(sheet, row, 7, ctx.teacherName ?? '', fontSize: 8,
        underline: true);
    ExcelStyleUtils.merge(sheet, row, 7, row, 8);

    ExcelStyleUtils.setCell(sheet, row, 9, 'SUBJECT:', bold: true, fontSize: 8);
    ExcelStyleUtils.setCell(sheet, row, 10, ctx.subject ?? '', fontSize: 8,
        underline: true);
    ExcelStyleUtils.merge(sheet, row, 10, row, 11);

    ExcelStyleUtils.setCell(sheet, row, totalCols - 1, ctx.quarterLabel,
        bold: true, fontSize: 9, bgColor: '#D9D9D9',
        hAlign: HorizontalAlign.Center, allBorders: true);
    row++;
    row++;

    return row;
  }

  static int _totalColumns(GradeExportContext ctx) {
    final wwCols = ctx.ww.items.isNotEmpty ? ctx.ww.items.length + 3 : 0;
    final ptCols = ctx.pt.items.isNotEmpty ? ctx.pt.items.length + 3 : 0;
    final qaCols = ctx.qa.items.isNotEmpty ? ctx.qa.items.length + 3 : 0;
    return 1 + wwCols + ptCols + qaCols + 2;
  }
}
