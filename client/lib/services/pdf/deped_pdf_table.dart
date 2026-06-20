import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:likha/services/grade_export_service.dart';

const double _nameWidth = 130.0;
const double _itemWidth = 26.0;
const double _tpsWidth = 30.0;
const double _gradeWidth = 36.0;

/// Top border for the header strip; the table below provides the bottom border.
/// Only the first container gets a left border; each container gets a right border
/// so borders between sections are shared, matching the table.
pw.BoxDecoration _headerStripTopBorder({required bool isFirst}) =>
    pw.BoxDecoration(
      border: pw.Border(
        top: const pw.BorderSide(color: PdfColors.black, width: 0.5),
        left: isFirst ? const pw.BorderSide(color: PdfColors.black, width: 0.5) : pw.BorderSide.none,
        right: const pw.BorderSide(color: PdfColors.black, width: 0.5),
      ),
    );

pw.Widget buildGradeTable(GradeExportContext ctx, {int startIdx = 0, int? endIdx}) {
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

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _buildSectionHeaderStrip(ctx),
      pw.Table(
        columnWidths: columnWidths,
        tableWidth: pw.TableWidth.min,
        border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
        children: [
          _columnHeaderRow(ctx),
          _hpsRow(ctx),
          ...studentSubset.map((row) => _studentRow(ctx, row)),
        ],
      ),
    ],
  );
}

pw.Widget _buildSectionHeaderStrip(GradeExportContext ctx) {
  final children = <pw.Widget>[];

  children.add(
    pw.Container(
      width: _nameWidth,
      height: 22,
      padding: const pw.EdgeInsets.all(2),
      decoration: _headerStripTopBorder(isFirst: true),
      child: pw.Center(
        child: pw.Text(
          "LEARNER'S NAMES",
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
    ),
  );

  for (final entry in [
    (ctx.ww, 'WRITTEN WORKS'),
    (ctx.pt, 'PERFORMANCE TASKS'),
    (ctx.qa, 'TERM ASSESSMENT'),
  ]) {
    final section = entry.$1;
    final label = entry.$2;
    if (section.items.isEmpty) continue;
    final totalWidth = section.items.length * _itemWidth + 3 * _tpsWidth;
    children.add(
      pw.Container(
        width: totalWidth,
        height: 22,
        padding: const pw.EdgeInsets.all(2),
        decoration: _headerStripTopBorder(isFirst: false),
        child: pw.Center(
          child: pw.Text(
            '$label (${section.weight.toStringAsFixed(0)}%)',
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ),
    );
  }

  children.add(
    pw.Container(
      width: _gradeWidth,
      height: 22,
      padding: const pw.EdgeInsets.all(2),
      decoration: _headerStripTopBorder(isFirst: false),
      child: pw.Center(
        child: pw.Text(
          'Initial\nGrade',
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
    ),
  );
  children.add(
    pw.Container(
      width: _gradeWidth,
      height: 22,
      padding: const pw.EdgeInsets.all(2),
      decoration: _headerStripTopBorder(isFirst: false),
      child: pw.Center(
        child: pw.Text(
          'Transmuted\nGrade',
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
    ),
  );

  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: children,
  );
}

pw.TableRow _columnHeaderRow(GradeExportContext ctx) {
  final children = <pw.Widget>[
    _headerCell('MALE', _nameWidth),
  ];

  children.addAll(_sectionColumnHeaders(ctx.ww));
  children.addAll(_sectionColumnHeaders(ctx.pt));
  children.addAll(_sectionColumnHeaders(ctx.qa));

  children.add(_headerCell('', _gradeWidth));
  children.add(_headerCell('', _gradeWidth));

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
    _dataCell('${row.index}. ${row.student.student.fullName}', _nameWidth,
        alignment: pw.Alignment.centerLeft),
  ];

  children.addAll(_sectionDataCells(row.ww));
  children.addAll(_sectionDataCells(row.pt));
  children.addAll(_sectionDataCells(row.qa));

  children.add(_dataCell(
    row.initialGrade != null ? row.initialGrade!.toStringAsFixed(2) : '',
    _gradeWidth,
  ));
  children.add(_dataCell(
    row.transmutedGrade?.toString() ?? '',
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
    {bool bold = false, PdfColor? bgColor, pw.Alignment alignment = pw.Alignment.center}) {
  return pw.Container(
    width: width,
    height: 18,
    padding: const pw.EdgeInsets.all(2),
    decoration: bgColor != null
        ? pw.BoxDecoration(color: bgColor)
        : null,
    child: pw.Align(
      alignment: alignment,
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
