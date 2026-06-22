import 'package:excel/excel.dart';
import 'package:likha/services/excel/excel_style_utils.dart';
import 'package:likha/services/grade_export_service.dart';

class ExcelTableBuilder {
  void build(Sheet sheet, GradeExportContext ctx, int startRow) {
    final colIndices = _calcColumnIndices(ctx);
    final nameCol = colIndices['nameCol']!;
    final wwStart = colIndices['wwStart']!;
    final ptStart = colIndices['ptStart']!;
    final qaStart = colIndices['qaStart']!;
    final initialCol = colIndices['initialCol']!;
    final qgCol = colIndices['qgCol']!;

    var row = startRow;

    _buildSectionHeaderRow(sheet, ctx, row, nameCol, wwStart, ptStart, qaStart, initialCol, qgCol);
    row++;

    _buildColumnHeaderRow(sheet, ctx, row, nameCol, wwStart, ptStart, qaStart, initialCol, qgCol);
    row++;

    _buildHpsRow(sheet, ctx, row, nameCol, wwStart, ptStart, qaStart, initialCol, qgCol);
    row++;

    _buildStudentRows(sheet, ctx, row, nameCol, wwStart, ptStart, qaStart, initialCol, qgCol);
  }

  Map<String, int> _calcColumnIndices(GradeExportContext ctx) {
    final ww = ctx.ww;
    final pt = ctx.pt;
    final qa = ctx.qa;

    final wwCols = ww.items.isNotEmpty ? ww.items.length + 3 : 0;
    final ptCols = pt.items.isNotEmpty ? pt.items.length + 3 : 0;
    final qaCols = qa.items.isNotEmpty ? qa.items.length + 3 : 0;

    var col = 0;
    final nameCol = col++;
    final wwStart = wwCols > 0 ? col : -1;
    col += wwCols;
    final ptStart = ptCols > 0 ? col : -1;
    col += ptCols;
    final qaStart = qaCols > 0 ? col : -1;
    col += qaCols;
    final initialCol = col++;
    final qgCol = col++;

    return {
      'nameCol': nameCol,
      'wwStart': wwStart,
      'ptStart': ptStart,
      'qaStart': qaStart,
      'initialCol': initialCol,
      'qgCol': qgCol,
    };
  }

  void _buildSectionHeaderRow(
    Sheet sheet,
    GradeExportContext ctx,
    int row,
    int nameCol,
    int wwStart,
    int ptStart,
    int qaStart,
    int initialCol,
    int qgCol,
  ) {
    final ww = ctx.ww;
    final pt = ctx.pt;
    final qa = ctx.qa;
    final wwCols = ww.items.isNotEmpty ? ww.items.length + 3 : 0;
    final ptCols = pt.items.isNotEmpty ? pt.items.length + 3 : 0;
    final qaCols = qa.items.isNotEmpty ? qa.items.length + 3 : 0;

    ExcelStyleUtils.setCell(sheet, row, nameCol, "LEARNERS' NAMES",
        bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
        vAlign: VerticalAlign.Center, bgColor: '#D9D9D9',
        allBorders: true);

    if (wwCols > 0) {
      ExcelStyleUtils.setCell(sheet, row, wwStart,
          'WRITTEN WORKS(${ww.weight.toStringAsFixed(0)}%)',
          bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
          bgColor: '#D9D9D9', allBorders: true);
      ExcelStyleUtils.merge(sheet, row, wwStart, row, wwStart + wwCols - 1);
    }

    if (ptCols > 0) {
      ExcelStyleUtils.setCell(sheet, row, ptStart,
          'PERFORMANCE TASKS(${pt.weight.toStringAsFixed(0)}%)',
          bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
          bgColor: '#D9D9D9', allBorders: true);
      ExcelStyleUtils.merge(sheet, row, ptStart, row, ptStart + ptCols - 1);
    }

    if (qaCols > 0) {
      ExcelStyleUtils.setCell(sheet, row, qaStart,
          'TERM ASSESSMENT(${qa.weight.toStringAsFixed(0)}%)',
          bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
          bgColor: '#D9D9D9', allBorders: true);
      ExcelStyleUtils.merge(sheet, row, qaStart, row, qaStart + qaCols - 1);
    }

    ExcelStyleUtils.setCell(sheet, row, initialCol, 'Initial Grade',
        bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
        vAlign: VerticalAlign.Center, bgColor: '#D9D9D9',
        allBorders: true);
    ExcelStyleUtils.setCell(sheet, row, qgCol, 'Term Grade',
        bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
        vAlign: VerticalAlign.Center, bgColor: '#D9D9D9',
        allBorders: true);
  }

  void _buildColumnHeaderRow(
    Sheet sheet,
    GradeExportContext ctx,
    int row,
    int nameCol,
    int wwStart,
    int ptStart,
    int qaStart,
    int initialCol,
    int qgCol,
  ) {
    final ww = ctx.ww;
    final pt = ctx.pt;
    final qa = ctx.qa;
    final wwCols = ww.items.isNotEmpty ? ww.items.length + 3 : 0;
    final ptCols = pt.items.isNotEmpty ? pt.items.length + 3 : 0;
    final qaCols = qa.items.isNotEmpty ? qa.items.length + 3 : 0;

    ExcelStyleUtils.setCell(sheet, row, nameCol, 'MALE',
        bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
        vAlign: VerticalAlign.Center, bgColor: '#D9D9D9',
        allBorders: true);

    if (wwCols > 0) {
      for (int i = 0; i < ww.items.length; i++) {
        ExcelStyleUtils.setCell(sheet, row, wwStart + i, '${i + 1}',
            bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
            bgColor: '#D9D9D9', allBorders: true);
      }
      ExcelStyleUtils.setCell(sheet, row, wwStart + ww.items.length, 'Total',
          bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
          bgColor: '#D9D9D9', allBorders: true);
      ExcelStyleUtils.setCell(sheet, row, wwStart + ww.items.length + 1, 'PS',
          bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
          bgColor: '#D9D9D9', allBorders: true);
      ExcelStyleUtils.setCell(sheet, row, wwStart + ww.items.length + 2, 'WS',
          bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
          bgColor: '#D9D9D9', allBorders: true);
    }

    if (ptCols > 0) {
      for (int i = 0; i < pt.items.length; i++) {
        ExcelStyleUtils.setCell(sheet, row, ptStart + i, '${i + 1}',
            bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
            bgColor: '#D9D9D9', allBorders: true);
      }
      ExcelStyleUtils.setCell(sheet, row, ptStart + pt.items.length, 'Total',
          bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
          bgColor: '#D9D9D9', allBorders: true);
      ExcelStyleUtils.setCell(sheet, row, ptStart + pt.items.length + 1, 'PS',
          bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
          bgColor: '#D9D9D9', allBorders: true);
      ExcelStyleUtils.setCell(sheet, row, ptStart + pt.items.length + 2, 'WS',
          bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
          bgColor: '#D9D9D9', allBorders: true);
    }

    if (qaCols > 0) {
      for (int i = 0; i < qa.items.length; i++) {
        ExcelStyleUtils.setCell(sheet, row, qaStart + i, '${i + 1}',
            bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
            bgColor: '#D9D9D9', allBorders: true);
      }
      ExcelStyleUtils.setCell(sheet, row, qaStart + qa.items.length, 'Total',
          bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
          bgColor: '#D9D9D9', allBorders: true);
      ExcelStyleUtils.setCell(sheet, row, qaStart + qa.items.length + 1, 'PS',
          bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
          bgColor: '#D9D9D9', allBorders: true);
      ExcelStyleUtils.setCell(sheet, row, qaStart + qa.items.length + 2, 'WS',
          bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
          bgColor: '#D9D9D9', allBorders: true);
    }

    ExcelStyleUtils.setCell(sheet, row, initialCol, 'Grade',
        bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
        bgColor: '#D9D9D9', allBorders: true);
    ExcelStyleUtils.setCell(sheet, row, qgCol, 'Grade',
        bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
        bgColor: '#D9D9D9', allBorders: true);
  }

  void _buildHpsRow(
    Sheet sheet,
    GradeExportContext ctx,
    int row,
    int nameCol,
    int wwStart,
    int ptStart,
    int qaStart,
    int initialCol,
    int qgCol,
  ) {
    final ww = ctx.ww;
    final pt = ctx.pt;
    final qa = ctx.qa;
    final wwCols = ww.items.isNotEmpty ? ww.items.length + 3 : 0;
    final ptCols = pt.items.isNotEmpty ? pt.items.length + 3 : 0;
    final qaCols = qa.items.isNotEmpty ? qa.items.length + 3 : 0;

    ExcelStyleUtils.setCell(sheet, row, nameCol, 'HIGHEST POSSIBLE SCORE',
        bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
        vAlign: VerticalAlign.Center, bgColor: '#D9D9D9',
        allBorders: true);

    if (wwCols > 0) {
      for (int i = 0; i < ww.items.length; i++) {
        ExcelStyleUtils.setCell(sheet, row, wwStart + i,
            ww.items[i].totalPoints.toStringAsFixed(0),
            bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
            bgColor: '#D9D9D9', allBorders: true);
      }
      ExcelStyleUtils.setCell(sheet, row, wwStart + ww.items.length,
          ww.hpsTotal.toStringAsFixed(0),
          bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
          bgColor: '#D9D9D9', allBorders: true);
      ExcelStyleUtils.setCell(sheet, row, wwStart + ww.items.length + 1,
          '100.00',
          bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
          bgColor: '#D9D9D9', allBorders: true);
      ExcelStyleUtils.setCell(sheet, row, wwStart + ww.items.length + 2,
          '${ww.weight.toStringAsFixed(0)}%',
          bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
          bgColor: '#FFFF99', allBorders: true);
    }

    if (ptCols > 0) {
      for (int i = 0; i < pt.items.length; i++) {
        ExcelStyleUtils.setCell(sheet, row, ptStart + i,
            pt.items[i].totalPoints.toStringAsFixed(0),
            bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
            bgColor: '#D9D9D9', allBorders: true);
      }
      ExcelStyleUtils.setCell(sheet, row, ptStart + pt.items.length,
          pt.hpsTotal.toStringAsFixed(0),
          bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
          bgColor: '#D9D9D9', allBorders: true);
      ExcelStyleUtils.setCell(sheet, row, ptStart + pt.items.length + 1,
          '100.00',
          bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
          bgColor: '#D9D9D9', allBorders: true);
      ExcelStyleUtils.setCell(sheet, row, ptStart + pt.items.length + 2,
          '${pt.weight.toStringAsFixed(0)}%',
          bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
          bgColor: '#FFFF99', allBorders: true);
    }

    if (qaCols > 0) {
      for (int i = 0; i < qa.items.length; i++) {
        ExcelStyleUtils.setCell(sheet, row, qaStart + i,
            qa.items[i].totalPoints.toStringAsFixed(0),
            bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
            bgColor: '#D9D9D9', allBorders: true);
      }
      ExcelStyleUtils.setCell(sheet, row, qaStart + qa.items.length,
          qa.hpsTotal.toStringAsFixed(0),
          bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
          bgColor: '#D9D9D9', allBorders: true);
      ExcelStyleUtils.setCell(sheet, row, qaStart + qa.items.length + 1,
          '100.00',
          bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
          bgColor: '#D9D9D9', allBorders: true);
      ExcelStyleUtils.setCell(sheet, row, qaStart + qa.items.length + 2,
          '${qa.weight.toStringAsFixed(0)}%',
          bold: true, fontSize: 8, hAlign: HorizontalAlign.Center,
          bgColor: '#FFFF99', allBorders: true);
    }

    ExcelStyleUtils.setCell(sheet, row, initialCol, '',
        bgColor: '#D9D9D9', allBorders: true);
    ExcelStyleUtils.setCell(sheet, row, qgCol, '',
        bgColor: '#D9D9D9', allBorders: true);
  }

  void _buildStudentRows(
    Sheet sheet,
    GradeExportContext ctx,
    int startRow,
    int nameCol,
    int wwStart,
    int ptStart,
    int qaStart,
    int initialCol,
    int qgCol,
  ) {
    final ww = ctx.ww;
    final pt = ctx.pt;
    final qa = ctx.qa;
    final wwCols = ww.items.isNotEmpty ? ww.items.length + 3 : 0;
    final ptCols = pt.items.isNotEmpty ? pt.items.length + 3 : 0;
    final qaCols = qa.items.isNotEmpty ? qa.items.length + 3 : 0;

    var row = startRow;

    for (final studentRow in ctx.studentRows) {
      ExcelStyleUtils.setCell(sheet, row, nameCol,
          '${studentRow.index}. ${studentRow.student.student.fullName}',
          fontSize: 8, allBorders: true);

      if (wwCols > 0) {
        for (int i = 0; i < studentRow.ww.scores.length; i++) {
          final score = studentRow.ww.scores[i];
          ExcelStyleUtils.setCell(sheet, row, wwStart + i,
              score != null ? score.toStringAsFixed(1) : '',
              fontSize: 8, hAlign: HorizontalAlign.Center,
              allBorders: true);
        }
        ExcelStyleUtils.setCell(sheet, row, wwStart + studentRow.ww.scores.length,
            studentRow.ww.total != null ? studentRow.ww.total!.toStringAsFixed(1) : '',
            fontSize: 8, hAlign: HorizontalAlign.Center,
            allBorders: true);
        ExcelStyleUtils.setCell(sheet, row, wwStart + studentRow.ww.scores.length + 1,
            studentRow.ww.ps != null ? studentRow.ww.ps!.toStringAsFixed(2) : '',
            fontSize: 8, hAlign: HorizontalAlign.Center,
            allBorders: true);
        ExcelStyleUtils.setCell(sheet, row, wwStart + studentRow.ww.scores.length + 2,
            studentRow.ww.ws != null ? studentRow.ww.ws!.toStringAsFixed(2) : '',
            fontSize: 8, hAlign: HorizontalAlign.Center,
            allBorders: true);
      }

      if (ptCols > 0) {
        for (int i = 0; i < studentRow.pt.scores.length; i++) {
          final score = studentRow.pt.scores[i];
          ExcelStyleUtils.setCell(sheet, row, ptStart + i,
              score != null ? score.toStringAsFixed(1) : '',
              fontSize: 8, hAlign: HorizontalAlign.Center,
              allBorders: true);
        }
        ExcelStyleUtils.setCell(sheet, row, ptStart + studentRow.pt.scores.length,
            studentRow.pt.total != null ? studentRow.pt.total!.toStringAsFixed(1) : '',
            fontSize: 8, hAlign: HorizontalAlign.Center,
            allBorders: true);
        ExcelStyleUtils.setCell(sheet, row, ptStart + studentRow.pt.scores.length + 1,
            studentRow.pt.ps != null ? studentRow.pt.ps!.toStringAsFixed(2) : '',
            fontSize: 8, hAlign: HorizontalAlign.Center,
            allBorders: true);
        ExcelStyleUtils.setCell(sheet, row, ptStart + studentRow.pt.scores.length + 2,
            studentRow.pt.ws != null ? studentRow.pt.ws!.toStringAsFixed(2) : '',
            fontSize: 8, hAlign: HorizontalAlign.Center,
            allBorders: true);
      }

      if (qaCols > 0) {
        for (int i = 0; i < studentRow.qa.scores.length; i++) {
          final score = studentRow.qa.scores[i];
          ExcelStyleUtils.setCell(sheet, row, qaStart + i,
              score != null ? score.toStringAsFixed(1) : '',
              fontSize: 8, hAlign: HorizontalAlign.Center,
              allBorders: true);
        }
        ExcelStyleUtils.setCell(sheet, row, qaStart + studentRow.qa.scores.length,
            studentRow.qa.total != null ? studentRow.qa.total!.toStringAsFixed(1) : '',
            fontSize: 8, hAlign: HorizontalAlign.Center,
            allBorders: true);
        ExcelStyleUtils.setCell(sheet, row, qaStart + studentRow.qa.scores.length + 1,
            studentRow.qa.ps != null ? studentRow.qa.ps!.toStringAsFixed(2) : '',
            fontSize: 8, hAlign: HorizontalAlign.Center,
            allBorders: true);
        ExcelStyleUtils.setCell(sheet, row, qaStart + studentRow.qa.scores.length + 2,
            studentRow.qa.ws != null ? studentRow.qa.ws!.toStringAsFixed(2) : '',
            fontSize: 8, hAlign: HorizontalAlign.Center,
            allBorders: true);
      }

      ExcelStyleUtils.setCell(sheet, row, initialCol,
          studentRow.initialGrade != null ? studentRow.initialGrade!.toStringAsFixed(2) : '',
          fontSize: 8, hAlign: HorizontalAlign.Center,
          allBorders: true);
      ExcelStyleUtils.setCell(sheet, row, qgCol,
          studentRow.transmutedGrade?.toString() ?? '',
          fontSize: 8, hAlign: HorizontalAlign.Center,
          allBorders: true);

      row++;
    }
  }
}
