import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/term_utils.dart';

class Sf9CoreValuesTable extends StatelessWidget {
  const Sf9CoreValuesTable({super.key});

  static const _coreValues = [
    (
      'Maka-Diyos',
      [
        "Expresses one's spiritual beliefs while respecting those of others",
        'Shows adherence to ethical principles by upholding truth and justice at all times',
        'Exhibits a deep sense of love for and service to the community and country',
      ],
    ),
    (
      'Makatao',
      [
        'Demonstrates and expresses pride in being a Filipino without looking down on others',
        'Listens attentively and responds appropriately to the opinions, ideas, and views of others',
        'Shows respect for and understanding of differences in culture, religion, and beliefs',
      ],
    ),
    (
      'Maka-Kalikasan',
      [
        'Shows care and concern for the environment',
        'Demonstrates resourcefulness and creativity in solving problems',
        'Exhibits a sense of responsibility for the sustainable use of resources',
      ],
    ),
    (
      'Maka-bansa',
      [
        'Demonstrates pride in being a Filipino without looking down on others',
        'Shows commitment to the ideals of democracy and nationalism',
        'Exhibits a deep sense of patriotism and love for the country',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const nameWidth = 120.0;
    const stmtWidth = 280.0;
    const qWidth = 50.0;
    const cellHeight = 44.0;

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
              _cell('Behavior Statements', stmtWidth, cellHeight, bold: true, align: Alignment.centerLeft),
              ...List.generate(termCountFromType(null), (i) =>
                _cell('T${i + 1}', qWidth, cellHeight, bold: true),
              ),
            ],
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          // Core value rows
          ..._coreValues.map((cv) {
            return Column(
              children: cv.$2.map((stmt) {
                final isFirst = stmt == cv.$2.first;
                return Row(
                  children: [
                    if (isFirst)
                      _cell(cv.$1, nameWidth, cellHeight, bold: true)
                    else
                      _cell('', nameWidth, cellHeight),
                    _cell(stmt, stmtWidth, cellHeight, align: Alignment.centerLeft, size: 10),
                    ...List.generate(termCountFromType(null), (i) =>
                      _cell('', qWidth, cellHeight),
                    ),
                  ],
                );
              }).toList(),
            );
          }),
          const Divider(height: 1, color: AppColors.borderLight),
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
