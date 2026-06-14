import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/presentation/controllers/teacher/tos/tos_detail_controller.dart';
import 'package:likha/presentation/providers/tos_provider.dart';
import 'package:likha/presentation/widgets/mobile/teacher/tos/tos_grid_table.dart';
import 'package:likha/presentation/widgets/mobile/teacher/tos/tos_summary_row.dart';
import 'package:likha/presentation/widgets/shared/dialogs/app_dialogs.dart';
import 'package:likha/presentation/widgets/shared/empty_states/tos_empty_competencies.dart';

class TosSpecificationGridSection extends ConsumerWidget {
  final TableOfSpecifications tos;
  final List<TosCompetency> competencies;
  final TosDetailController controller;

  const TosSpecificationGridSection({
    super.key,
    required this.tos,
    required this.competencies,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Specification Grid',
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
            message: 'No competencies yet. Add competencies to see the grid.',
          )
        else ...[
          TosGridTable(
            competencies: competencies,
            tos: tos,
            onCellTap: (competencyId, levelKey, currentOverride) {
              controller.prepareCellOverride(currentOverride);
              AppDialogs.showInput(
                context: context,
                title: 'Set Item Count',
                controller: controller.cellOverrideController,
                labelText: 'Number of items (leave blank to auto)',
                confirmLabel: 'Save',
                keyboardType: TextInputType.number,
                onConfirm: () {
                  final raw = controller.cellOverrideController.text.trim();
                  final override = raw.isEmpty ? null : int.tryParse(raw);
                  ref
                      .read(tosProvider.notifier)
                      .updateCompetency(
                    competencyId,
                    {'${levelKey}_count': override},
                  );
                },
              );
            },
          ),
          const SizedBox(height: 12),
          TosSummaryRow(
            competencies: competencies,
            totalItems: tos.totalItems,
            timeUnit: tos.timeUnit,
          ),
        ],
      ],
    );
  }
}
