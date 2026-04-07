import 'package:flutter/material.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';

class TosGridTable extends StatelessWidget {
  final List<TosCompetency> competencies;
  final String classificationMode;
  final int totalItems;

  const TosGridTable({
    super.key,
    required this.competencies,
    required this.classificationMode,
    required this.totalItems,
  });

  List<String> get _cognitiveHeaders {
    if (classificationMode == 'blooms') {
      return ['R', 'U', 'Ap', 'An', 'E', 'C'];
    }
    return ['Easy', 'Avg', 'Diff'];
  }

  @override
  Widget build(BuildContext context) {
    final totalDays = competencies.fold<int>(0, (sum, c) => sum + c.daysTaught);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(11),
                  topRight: Radius.circular(11),
                ),
              ),
              child: Row(
                children: [
                  _headerCell('Competency', 200),
                  _headerCell('Days', 56),
                  _headerCell('%', 56),
                  ..._cognitiveHeaders.map((h) => _headerCell(h, 48)),
                  _headerCell('Total', 56),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            // Data rows
            ...competencies.asMap().entries.map((entry) {
              final c = entry.value;
              final weight = totalDays > 0
                  ? (c.daysTaught / totalDays * 100)
                  : 0.0;
              final targetItems = totalDays > 0
                  ? (weight * totalItems / 100).round()
                  : 0;

              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFFEEEEEE),
                      width: entry.key < competencies.length - 1 ? 1 : 0,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    _dataCell(
                      c.competencyCode != null
                          ? '${c.competencyCode} - ${c.competencyText}'
                          : c.competencyText,
                      200,
                    ),
                    _dataCell('${c.daysTaught}', 56, align: TextAlign.center),
                    _dataCell('${weight.toStringAsFixed(1)}%', 56, align: TextAlign.center),
                    ..._cognitiveHeaders.map((_) => _dataCell('-', 48, align: TextAlign.center)),
                    _dataCell('$targetItems', 56, align: TextAlign.center, bold: true),
                  ],
                ),
              );
            }),
            // Totals row
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF0F0F0),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(11),
                  bottomRight: Radius.circular(11),
                ),
              ),
              child: Row(
                children: [
                  _dataCell('TOTAL', 200, bold: true),
                  _dataCell('$totalDays', 56, align: TextAlign.center, bold: true),
                  _dataCell('100%', 56, align: TextAlign.center, bold: true),
                  ..._cognitiveHeaders.map((_) => _dataCell('-', 48, align: TextAlign.center)),
                  _dataCell('$totalItems', 56, align: TextAlign.center, bold: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF666666),
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _dataCell(
    String text,
    double width, {
    TextAlign align = TextAlign.left,
    bool bold = false,
  }) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: const Color(0xFF2B2B2B),
          ),
          textAlign: align,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
