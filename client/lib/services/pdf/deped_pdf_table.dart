import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:likha/services/grade_export_service.dart';

const double _nameWidth = 130.0;
const double _itemWidth = 26.0;
const double _tpsWidth = 30.0;
const double _gradeWidth = 36.0;

/// Yellow color for WS weight highlighting
const PdfColor _yellow = PdfColor(1.0, 1.0, 0.6);

pw.Table buildGradeTable(GradeExportContext ctx, {int startIdx = 0, int? endIdx}) {
  final ww = ctx.ww;
  final pt = ctx.pt;
  final qa = ctx.qa;

  final wwCols = ww.items.isNotEmpty ? ww.items.length + 3 : 0;
  final ptCols = pt.items.isNotEmpty ? pt.items.length + 3 : 0;
  final qaCols = qa.items.isNotEmpty ? qa.items.length + 3 : 0;

  final columnWidths = <int, pw.TableColumnWidth>{};
  var colIdx = 0;
  columnWidths[colIdx++] = const pw.FixedColumnWidth(_nameWidth);
  for (int i = 0; i < wwCols; i++) {
    columnWidths[colIdx++] =
        pw.FixedColumnWidth(i < ww.items.length ? _itemWidth : _tpsWidth);
  }
  for (int i = 0; i < ptCols; i++) {
    columnWidths[colIdx++] =
        pw.FixedColumnWidth(i < pt.items.length ? _itemWidth : _tpsWidth);
  }
  for (int i = 0; i < qaCols; i++) {
    columnWidths[colIdx++] =
        pw.FixedColumnWidth(i < qa.items.length ? _itemWidth : _tpsWidth);
  }
  columnWidths[colIdx++] = const pw.FixedColumnWidth(_gradeWidth);
  columnWidths[colIdx++] = const pw.FixedColumnWidth(_gradeWidth);

  final studentSubset = endIdx != null
      ? ctx.studentRows.sublist(startIdx, endIdx)
      : ctx.studentRows.sublist(startIdx);

  return pw.Table(
    columnWidths: columnWidths,
    border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
    children: [
      _sectionHeaderRow(ctx),
      _columnHeaderRow(ctx),
      _hpsRow(ctx),
      ...studentSubset.map((row) => _studentRow(ctx, row)),
    ],
  );
}

pw.TableRow _sectionHeaderRow(GradeExportContext ctx) {
  final children = <pw.Widget>[
    _headerCell("LEARNERS' NAMES", _nameWidth),
  ];

  children.addAll(_sectionHeaderCells(ctx.ww, 'WRITTEN WORKS'));
  children.addAll(_sectionHeaderCells(ctx.pt, 'PERFORMANCE TASKS'));
  children.addAll(_sectionHeaderCells(ctx.qa, 'QUARTERLY ASSESSMENT'));

  children.add(_headerCell('Initial\nGrade', _gradeWidth));
  children.add(_headerCell('Quarterly\nGrade', _gradeWidth));

  return pw.TableRow(
    children: children,
  );
}

List<pw.Widget> _sectionHeaderCells(SectionInfo section, String label) {
  final cells = <pw.Widget>[];
  if (section.items.isEmpty) return cells;

  final totalWidth = (section.items.length * _itemWidth) + (_tpsWidth * 3);
  cells.add(
    pw.Container(
      width: totalWidth,
      height: 22,
      padding: const pw.EdgeInsets.all(2),
      child: pw.Center(
        child: pw.Text(
          '$label(${section.weight.toStringAsFixed(0)}%)',
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
    ),
  );
  // Add empty placeholders for remaining columns in this section
  for (int i = 1; i < section.items.length + 3; i++) {
    cells.add(pw.Container(width: i < section.items.length ? _itemWidth : _tpsWidth, height: 22));
  }
  return cells;
}

pw.TableRow _columnHeaderRow(GradeExportContext ctx) {
  final children = <pw.Widget>[
    _headerCell('MALE', _nameWidth),
  ];

  children.addAll(_sectionColumnHeaders(ctx.ww));
  children.addAll(_sectionColumnHeaders(ctx.pt));
  children.addAll(_sectionColumnHeaders(ctx.qa));

  children.add(_headerCell('Grade', _gradeWidth));
  children.add(_headerCell('Grade', _gradeWidth));

  return pw.TableRow(
    children: children,
  );
}

pw.TableRow _hpsRow(GradeExportContext ctx) {
  final children = <pw.Widget>[
    _dataCell('HIGHEST POSSIBLE SCORE', _nameWidth, bold: true),
  ];

  children.addAll(_sectionHpsCells(ctx.ww));
  children.addAll(_sectionHpsCells(ctx.pt));
  children.addAll(_sectionHpsCells(ctx.qa));

  children.add(_dataCell('', _gradeWidth));
  children.add(_dataCell('', _gradeWidth));

  return pw.TableRow(
    children: children,
  );
}

pw.TableRow _studentRow(GradeExportContext ctx, StudentExportRow row) {
  final children = <pw.Widget>[
    _dataCell('${row.index}. ${row.student.student.fullName}', _nameWidth),
  ];

  children.addAll(_sectionDataCells(row.ww));
  children.addAll(_sectionDataCells(row.pt));
  children.addAll(_sectionDataCells(row.qa));

  children.add(_dataCell(
    row.initialGrade != null ? row.initialGrade!.toStringAsFixed(2) : '',
    _gradeWidth,
  ));
  children.add(_dataCell(
    row.quarterlyGrade?.toString() ?? '',
    _gradeWidth,
  ));

  return pw.TableRow(children: children);
}

List<pw.Widget> _sectionColumnHeaders(SectionInfo section) {
  final cells = <pw.Widget>[];
  for (int i = 0; i < section.items.length; i++) {
    cells.add(_headerCell('${i + 1}', _itemWidth));
  }
  if (section.items.isNotEmpty) {
    cells.add(_headerCell('Total', _tpsWidth));
    cells.add(_headerCell('PS', _tpsWidth));
    cells.add(_headerCell('WS', _tpsWidth));
  }
  return cells;
}

List<pw.Widget> _sectionHpsCells(SectionInfo section) {
  final cells = <pw.Widget>[];
  for (final item in section.items) {
    cells.add(_dataCell(item.totalPoints.toStringAsFixed(0), _itemWidth, bold: true));
  }
  if (section.items.isNotEmpty) {
    cells.add(_dataCell(section.hpsTotal.toStringAsFixed(0), _tpsWidth, bold: true));
    cells.add(_dataCell('100.00', _tpsWidth, bold: true));
    // WS weight cell highlighted yellow
    cells.add(_dataCell(
      '${section.weight.toStringAsFixed(0)}%',
      _tpsWidth,
      bold: true,
      bgColor: _yellow,
    ));
  }
  return cells;
}

List<pw.Widget> _sectionDataCells(SectionResult result) {
  final cells = <pw.Widget>[];
  for (final score in result.scores) {
    cells.add(_dataCell(
      score != null ? score.toStringAsFixed(1) : '',
      _itemWidth,
    ));
  }
  if (result.scores.isNotEmpty) {
    cells.add(_dataCell(
      result.total != null ? result.total!.toStringAsFixed(1) : '',
      _tpsWidth,
    ));
    cells.add(_dataCell(
      result.ps != null ? result.ps!.toStringAsFixed(2) : '',
      _tpsWidth,
    ));
    cells.add(_dataCell(
      result.ws != null ? result.ws!.toStringAsFixed(2) : '',
      _tpsWidth,
    ));
  }
  return cells;
}

pw.Widget _headerCell(String text, double width) {
  return pw.Container(
    width: width,
    height: 22,
    padding: const pw.EdgeInsets.all(2),
    child: pw.Center(
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
      ),
    ),
  );
}

pw.Widget _dataCell(String text, double width,
    {bool bold = false, PdfColor? bgColor}) {
  return pw.Container(
    width: width,
    height: 18,
    padding: const pw.EdgeInsets.all(2),
    decoration: bgColor != null
        ? pw.BoxDecoration(color: bgColor)
        : null,
    child: pw.Center(
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    ),
  );
}
