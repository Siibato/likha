import 'package:flutter/material.dart';
import 'package:likha/core/constants/core_values_constants.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/term_utils.dart';
import 'package:likha/domain/grading/entities/sf9.dart';

class Sf9CoreValuesTable extends StatelessWidget {
  final List<Sf9CoreValueMarking> coreValues;

  const Sf9CoreValuesTable({
    super.key,
    this.coreValues = const [],
  });

  String? _getMarking(int statementId, int term) {
    final match = coreValues
        .where((v) => v.coreValueId == statementId && v.termNumber == term)
        .firstOrNull;
    return match?.marking;
  }

  @override
  Widget build(BuildContext context) {
    const nameWidth = 180.0;
    const qWidth = 50.0;
    const cellHeight = 44.0;
    final numTerms = termCountFromType(null);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.backgroundTertiary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: const Text(
              "REPORT ON LEARNER'S OBSERVED VALUES",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.accentCharcoal,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          // Header row
          Row(
            children: [
              _cell('Core Values', nameWidth, cellHeight, bold: true),
              _vDivider(cellHeight),
              _flexCell('Behavior Statements', cellHeight, bold: true, align: Alignment.centerLeft),
              _vDivider(cellHeight),
              ...List.generate(numTerms, (i) => [
                _cell('T${i + 1}', qWidth, cellHeight, bold: true),
                if (i < numTerms - 1) _vDivider(cellHeight),
              ]).expand((x) => x),
            ],
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          ...coreValueNames.asMap().entries.map((cvEntry) {
            final cvIndex = cvEntry.key;
            final cvName = cvEntry.value;
            final numberedName = '${cvIndex + 1}. $cvName';
            final stmts = statementsForCoreValue(cvName);
            return Column(
              children: [
                ...stmts.asMap().entries.expand((entry) {
                  final isFirst = entry.key == 0;
                  final stmt = entry.value;
                  return [
                    Row(
                      children: [
                        if (isFirst)
                          _cell(numberedName, nameWidth, cellHeight, bold: true, align: Alignment.centerLeft)
                        else
                          _cell('', nameWidth, cellHeight, align: Alignment.centerLeft),
                        _vDivider(cellHeight),
                        _flexCell(stmt.statement, cellHeight, align: Alignment.centerLeft, size: 12),
                        _vDivider(cellHeight),
                        ...List.generate(numTerms, (i) {
                          final marking = _getMarking(stmt.id, i + 1);
                          return [
                            _cell(marking ?? '', qWidth, cellHeight, bold: marking != null),
                            if (i < numTerms - 1) _vDivider(cellHeight),
                          ];
                        }).expand((x) => x),
                      ],
                    ),
                    const Divider(height: 1, color: AppColors.borderLight),
                  ];
                }),
              ],
            );
          }),
          // Marking legend
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Marking Legend:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accentCharcoal),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    _legendItem('AO', 'Always Observed'),
                    _legendItem('SO', 'Sometimes Observed'),
                    _legendItem('RO', 'Rarely Observed'),
                    _legendItem('NO', 'Not Observed'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDivider(double height) {
    return Container(width: 1, height: height, color: AppColors.borderLight);
  }

  Widget _flexCell(
    String text,
    double height, {
    bool bold = false,
    Alignment align = Alignment.center,
    double size = 12,
  }) {
    return Expanded(
      child: SizedBox(
        height: height,
        child: Align(
          alignment: align,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              text,
              style: TextStyle(
                fontSize: size,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: AppColors.accentCharcoal,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Widget _legendItem(String code, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$code - ',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accentCharcoal),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.foregroundSecondary),
        ),
      ],
    );
  }

  Widget _cell(
    String text,
    double width,
    double height, {
    bool bold = false,
    Alignment align = Alignment.center,
    double size = 12,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: Align(
        alignment: align,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            text,
            style: TextStyle(
              fontSize: size,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: AppColors.accentCharcoal,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
