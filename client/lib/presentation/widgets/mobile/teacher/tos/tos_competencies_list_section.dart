import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/presentation/controllers/teacher/tos/tos_detail_controller.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/bulk_paste_sheet.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/melcs_search_sheet.dart';
import 'package:likha/presentation/widgets/mobile/teacher/tos/tos_add_competency_button.dart';
import 'package:likha/presentation/widgets/mobile/teacher/tos/tos_editable_competency_row.dart';
import 'package:likha/presentation/widgets/mobile/teacher/tos/tos_outlined_button.dart';

class TosCompetenciesListSection extends StatelessWidget {
  final TableOfSpecifications tos;
  final List<TosCompetency> competencies;
  final TosDetailController controller;

  const TosCompetenciesListSection({
    super.key,
    required this.tos,
    required this.competencies,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final totalDays = competencies.fold<int>(
        0, (s, c) => s + c.timeUnitsTaught);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        ...competencies.map((c) => TosEditableCompetencyRow(
          competency: c,
          totalDays: totalDays,
          timeUnit: tos.timeUnit,
          controller: controller,
        )),
        const SizedBox(height: 16),
        TosAddCompetencyButton(
          tosId: tos.id,
          timeUnit: tos.timeUnit,
          controller: controller,
        ),
        const SizedBox(height: 8),
        TosOutlinedButton(
          icon: Icons.search,
          label: 'Import from MELCs',
          onTap: () => MelcsSearchSheet.show(context, tos.id),
        ),
        const SizedBox(height: 8),
        TosOutlinedButton(
          icon: Icons.paste,
          label: 'Bulk Paste',
          onTap: () => BulkPasteSheet.show(context, tos.id),
        ),
      ],
    );
  }
}
