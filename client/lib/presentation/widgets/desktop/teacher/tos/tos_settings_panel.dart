import 'package:flutter/material.dart';

import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/presentation/widgets/shared/cards/info_panel.dart';
import 'package:likha/presentation/widgets/desktop/teacher/tos/tos_settings_row.dart';

/// Desktop settings panel for a TOS detail page.
class TosSettingsPanel extends StatelessWidget {
  final TableOfSpecifications tos;
  final List<TosCompetency> competencies;

  const TosSettingsPanel({
    super.key,
    required this.tos,
    required this.competencies,
  });

  @override
  Widget build(BuildContext context) {
    final modeLabel = tos.classificationMode == 'blooms'
        ? "Bloom's Taxonomy"
        : 'Difficulty Level';
    final totalDays =
        competencies.fold<int>(0, (sum, c) => sum + c.timeUnitsTaught);

    return InfoPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.foregroundDark,
            ),
          ),
          const SizedBox(height: 12),
          TosSettingsRow(label: 'Quarter', value: 'Q${tos.gradingPeriodNumber}'),
          TosSettingsRow(label: 'Mode', value: modeLabel),
          TosSettingsRow(label: 'Total Items', value: '${tos.totalItems}'),
          TosSettingsRow(label: 'Competencies', value: '${competencies.length}'),
          TosSettingsRow(
            label: 'Total ${tos.timeUnit == 'hours' ? 'Hours' : 'Days'}',
            value: '$totalDays',
          ),
        ],
      ),
    );
  }
}
