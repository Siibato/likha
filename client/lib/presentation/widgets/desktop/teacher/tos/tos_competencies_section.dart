import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/presentation/controllers/teacher/tos/tos_detail_controller.dart';
import 'package:likha/presentation/widgets/desktop/teacher/tos/tos_add_competency_button.dart';
import 'package:likha/presentation/widgets/desktop/teacher/tos/tos_editable_competency_tile.dart';
import 'package:likha/presentation/widgets/desktop/teacher/tos/tos_settings_panel.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/bulk_paste_sheet.dart';
import 'package:likha/presentation/widgets/desktop/teacher/tos/melcs_search_dialog.dart';
import 'package:likha/presentation/widgets/shared/empty_states/tos_empty_competencies.dart';

class TosCompetenciesSection extends StatelessWidget {
  final TableOfSpecifications tos;
  final List<TosCompetency> competencies;
  final TosDetailController controller;

  const TosCompetenciesSection({
    super.key,
    required this.tos,
    required this.competencies,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TosSettingsPanel(
          tos: tos,
          competencies: competencies,
        ),
        const SizedBox(height: 20),
        const Text(
          'Competencies',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.foregroundDark,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        if (competencies.isEmpty)
          const TosEmptyCompetencies(
            message: 'No competencies added yet.',
          )
        else
          ...competencies.map(
            (c) => TosEditableCompetencyTile(
              competency: c,
              timeUnit: tos.timeUnit,
              controller: controller,
            ),
          ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            TosAddCompetencyButton(
              tosId: tos.id,
              timeUnit: tos.timeUnit,
              controller: controller,
            ),
            OutlinedButton.icon(
              onPressed: () => MelcsSearchDialog.show(context, tos.id),
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Import from MELCs'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.foregroundPrimary,
                side: const BorderSide(color: AppColors.borderLight),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => BulkPasteSheet.show(context, tos.id),
              icon: const Icon(Icons.paste, size: 18),
              label: const Text('Bulk Paste'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.foregroundPrimary,
                side: const BorderSide(color: AppColors.borderLight),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
