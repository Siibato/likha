import 'package:excel/excel.dart';

class ExcelStyleUtils {
  static final _black = ExcelColor.fromHexString('FF000000');
  static final _yellow = ExcelColor.fromHexString('FFFFFF99');
  static final _grey = ExcelColor.fromHexString('FFD9D9D9');

  static Border _thinBorder() => Border(
    borderStyle: BorderStyle.Thin,
    borderColorHex: _black,
  );

  static CellStyle _cellStyle({
    bool bold = false,
    int fontSize = 10,
    HorizontalAlign? hAlign,
    VerticalAlign? vAlign,
    ExcelColor? bgColor,
    bool allBorders = false,
    bool underline = false,
  }) {
    final border = _thinBorder();
    return CellStyle(
      bold: bold,
      fontSize: fontSize,
      horizontalAlign: hAlign ?? HorizontalAlign.Left,
      verticalAlign: vAlign ?? VerticalAlign.Bottom,
      backgroundColorHex: bgColor ?? ExcelColor.none,
      leftBorder: allBorders ? border : null,
      rightBorder: allBorders ? border : null,
      topBorder: allBorders ? border : null,
      bottomBorder: allBorders || underline ? border : null,
    );
  }

  static void setCell(
    Sheet sheet,
    int row,
    int col,
    String value, {
    bool bold = false,
    int fontSize = 10,
    HorizontalAlign? hAlign,
    VerticalAlign? vAlign,
    String? bgColor,
    bool allBorders = false,
    bool underline = false,
  }) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(
      columnIndex: col,
      rowIndex: row,
    ));
    cell.value = TextCellValue(value);

    ExcelColor? excelColor;
    if (bgColor != null) {
      if (bgColor == '#FFFF99') {
        excelColor = _yellow;
      } else if (bgColor == '#D9D9D9') {
        excelColor = _grey;
      } else {
        excelColor = ExcelColor.fromHexString('FF${bgColor.replaceAll('#', '')}');
      }
    }

    cell.cellStyle = _cellStyle(
      bold: bold,
      fontSize: fontSize,
      hAlign: hAlign,
      vAlign: vAlign,
      bgColor: excelColor,
      allBorders: allBorders,
      underline: underline,
    );
  }

  static void merge(Sheet sheet, int startRow, int startCol, int endRow, int endCol) {
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: startCol, rowIndex: startRow),
      CellIndex.indexByColumnRow(columnIndex: endCol, rowIndex: endRow),
    );
  }
}
