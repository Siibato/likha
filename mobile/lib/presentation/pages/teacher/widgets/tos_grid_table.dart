import 'package:flutter/material.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';

class TosGridTable extends StatelessWidget {
  final List<TosCompetency> competencies;
  final TableOfSpecifications tos;

  /// Called when a cognitive cell is tapped.
  /// [competencyId] — the competency being edited.
  /// [levelKey] — one of 'easy', 'medium', 'hard'.
  /// [currentOverride] — the current per-competency override, or null if auto.
  final void Function(String competencyId, String levelKey, int? currentOverride)? onCellTap;

  const TosGridTable({
    super.key,
    required this.competencies,
    required this.tos,
    this.onCellTap,
  });

  bool get _isBloomsMode => tos.classificationMode == 'blooms';

  List<String> get _cognitiveHeaders {
    if (_isBloomsMode) return ['R', 'U', 'Ap', 'An', 'E', 'C'];
    return ['Easy', 'Avg', 'Diff'];
  }

  String get _timeUnitLabel =>
      tos.timeUnit == 'hours' ? 'Hours' : 'Days';

  @override
  Widget build(BuildContext context) {
    final totalDays =
        competencies.fold<int>(0, (sum, c) => sum + c.daysTaught);

    // Fixed widths: Days(56) + %(56) + cognitive cols(48 each) + Total(56)
    const double fixedColWidth = 56 + 72 + 56; // Days + % + Total
    const double cogColWidth = 48;
    final double totalFixed =
        fixedColWidth + _cognitiveHeaders.length * cogColWidth;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double competencyWidth =
            (constraints.maxWidth - totalFixed).clamp(120.0, double.infinity);

        return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Column(
          children: [
            // Header row
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
                  _headerCell('Competency', competencyWidth),
                  _headerCell(_timeUnitLabel, 56),
                  _headerCell('%', 72),
                  ..._cognitiveHeaders.map((h) => _headerCell(h, 48)),
                  _headerCell('Total', 56),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            // Data rows
            ...competencies.asMap().entries.map((entry) {
              final idx = entry.key;
              final c = entry.value;
              final weight =
                  totalDays > 0 ? c.daysTaught / totalDays * 100 : 0.0;
              final targetItems =
                  totalDays > 0 ? (weight * tos.totalItems / 100).round() : 0;

              final easyItems = c.easyCount ??
                  (targetItems * tos.easyPercentage / 100).round();
              final mediumItems = c.mediumCount ??
                  (targetItems * tos.mediumPercentage / 100).round();
              final hardItems = c.hardCount ??
                  (targetItems * tos.hardPercentage / 100).round();

              final cells = _buildCognitiveCells(
                context: context,
                competency: c,
                targetItems: targetItems,
                easyItems: easyItems,
                mediumItems: mediumItems,
                hardItems: hardItems,
                easyIsOverride: c.easyCount != null,
                mediumIsOverride: c.mediumCount != null,
                hardIsOverride: c.hardCount != null,
              );

              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFFEEEEEE),
                      width: idx < competencies.length - 1 ? 1 : 0,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    _dataCell(
                      c.competencyCode != null
                          ? '${c.competencyCode} - ${c.competencyText}'
                          : c.competencyText,
                      competencyWidth,
                    ),
                    _dataCell('${c.daysTaught}', 56,
                        align: TextAlign.center),
                    _dataCell(
                        '${weight.toStringAsFixed(1)}%', 72,
                        align: TextAlign.center),
                    ...cells,
                    _dataCell('$targetItems', 56,
                        align: TextAlign.center, bold: true),
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
                  _dataCell('TOTAL', competencyWidth, bold: true),
                  _dataCell('$totalDays', 56,
                      align: TextAlign.center, bold: true),
                  _dataCell('100%', 72,
                      align: TextAlign.center, bold: true),
                  ..._cognitiveHeaders.map(
                      (_) => _dataCell('-', 48, align: TextAlign.center)),
                  _dataCell('${tos.totalItems}', 56,
                      align: TextAlign.center, bold: true),
                ],
              ),
            ),
          ],
        ),
          ),
        ),
      );
      },
    );
  }

  List<Widget> _buildCognitiveCells({
    required BuildContext context,
    required TosCompetency competency,
    required int targetItems,
    required int easyItems,
    required int mediumItems,
    required int hardItems,
    required bool easyIsOverride,
    required bool mediumIsOverride,
    required bool hardIsOverride,
  }) {
    if (!_isBloomsMode) {
      // Difficulty mode: 3 columns → easy, avg(medium), diff(hard)
      return [
        _tappableCell(
          context,
          value: '$easyItems',
          isOverride: easyIsOverride,
          onTap: onCellTap == null
              ? null
              : () => onCellTap!(competency.id, 'easy', competency.easyCount),
        ),
        _tappableCell(
          context,
          value: '$mediumItems',
          isOverride: mediumIsOverride,
          onTap: onCellTap == null
              ? null
              : () =>
                  onCellTap!(competency.id, 'medium', competency.mediumCount),
        ),
        _tappableCell(
          context,
          value: '$hardItems',
          isOverride: hardIsOverride,
          onTap: onCellTap == null
              ? null
              : () =>
                  onCellTap!(competency.id, 'hard', competency.hardCount),
        ),
      ];
    }

    // Blooms mode: 6 columns (R, U, Ap, An, E, C)
    // Use 6 individual bloom percentages from the TOS; when there is a
    // per-competency bucket override split proportionally by bloom ratios.
    final int r, u, ap, an, e, c;

    if (competency.easyCount != null) {
      // Override for easy bucket → split R/U proportionally
      final totalRU = tos.rememberingPercentage + tos.understandingPercentage;
      final rRatio = totalRU > 0 ? tos.rememberingPercentage / totalRU : 0.5;
      r = (easyItems * rRatio).round();
      u = easyItems - r;
    } else {
      r = (targetItems * tos.rememberingPercentage / 100).round();
      u = (targetItems * tos.understandingPercentage / 100).round();
    }

    if (competency.mediumCount != null) {
      // Override for medium bucket → split Ap/An proportionally
      final totalApAn = tos.applyingPercentage + tos.analyzingPercentage;
      final apRatio = totalApAn > 0 ? tos.applyingPercentage / totalApAn : 0.5;
      ap = (mediumItems * apRatio).round();
      an = mediumItems - ap;
    } else {
      ap = (targetItems * tos.applyingPercentage / 100).round();
      an = (targetItems * tos.analyzingPercentage / 100).round();
    }

    if (competency.hardCount != null) {
      // Override for hard bucket → split E/C proportionally
      final totalEC = tos.evaluatingPercentage + tos.creatingPercentage;
      final eRatio = totalEC > 0 ? tos.evaluatingPercentage / totalEC : 0.5;
      e = (hardItems * eRatio).round();
      c = hardItems - e;
    } else {
      e = (targetItems * tos.evaluatingPercentage / 100).round();
      c = (targetItems * tos.creatingPercentage / 100).round();
    }

    Widget bloomCell(String val, bool isOverride, String levelKey, int? override) {
      return _tappableCell(
        context,
        value: val,
        isOverride: isOverride,
        onTap: onCellTap == null
            ? null
            : () => onCellTap!(competency.id, levelKey, override),
      );
    }

    return [
      bloomCell('$r', easyIsOverride, 'easy', competency.easyCount),
      bloomCell('$u', easyIsOverride, 'easy', competency.easyCount),
      bloomCell('$ap', mediumIsOverride, 'medium', competency.mediumCount),
      bloomCell('$an', mediumIsOverride, 'medium', competency.mediumCount),
      bloomCell('$e', hardIsOverride, 'hard', competency.hardCount),
      bloomCell('$c', hardIsOverride, 'hard', competency.hardCount),
    ];
  }

  Widget _tappableCell(
    BuildContext context, {
    required String value,
    required bool isOverride,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: 48,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          color: Colors.transparent,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isOverride ? FontWeight.w700 : FontWeight.w400,
              color: isOverride
                  ? const Color(0xFF2B6CB0)
                  : const Color(0xFF2B2B2B),
            ),
            textAlign: TextAlign.center,
          ),
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
