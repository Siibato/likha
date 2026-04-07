import 'package:flutter/material.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/info_panel.dart';
import 'package:likha/presentation/pages/shared/widgets/primitives/info_row.dart';

class TosSettingsCard extends StatelessWidget {
  final TableOfSpecifications tos;
  final int competencyCount;
  final int totalDays;

  const TosSettingsCard({
    super.key,
    required this.tos,
    required this.competencyCount,
    required this.totalDays,
  });

  @override
  Widget build(BuildContext context) {
    final modeLabel = tos.classificationMode == 'blooms'
        ? "Bloom's Taxonomy"
        : 'Difficulty Level';

    return InfoPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(label: 'Quarter', value: 'Quarter ${tos.quarter}'),
          const SizedBox(height: 10),
          InfoRow(label: 'Classification', value: modeLabel),
          const SizedBox(height: 10),
          InfoRow(label: 'Total Items', value: '${tos.totalItems}'),
          const SizedBox(height: 10),
          InfoRow(label: 'Competencies', value: '$competencyCount'),
          const SizedBox(height: 10),
          InfoRow(label: 'Total Days Taught', value: '$totalDays'),
        ],
      ),
    );
  }
}
