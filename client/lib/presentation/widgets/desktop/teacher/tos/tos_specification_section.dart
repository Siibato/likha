import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/presentation/providers/tos_provider.dart';
import 'package:likha/presentation/widgets/desktop/teacher/tos/tos_missing_points_banner.dart';
import 'package:likha/presentation/widgets/mobile/teacher/tos/tos_grid_table.dart';
import 'package:likha/presentation/widgets/mobile/teacher/tos/tos_summary_row.dart';
import 'package:likha/presentation/widgets/shared/empty_states/tos_empty_competencies.dart';

class TosSpecificationSection extends ConsumerWidget {
  final TableOfSpecifications tos;
  final List<TosCompetency> competencies;

  const TosSpecificationSection({
    super.key,
    required this.tos,
    required this.competencies,
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
            message: 'Add competencies to see the grid.',
          )
        else ...[
          TosGridTable(
            competencies: competencies,
            tos: tos,
            onCellChanged: (id, key, val) => ref
                .read(tosProvider.notifier)
                .updateCompetency(id, {'${key}_count': val}),
            onCompetencyTextChanged: (id, text) => ref
                .read(tosProvider.notifier)
                .updateCompetency(id, {'competency_text': text}),
            onDaysTaughtChanged: (id, days) => ref
                .read(tosProvider.notifier)
                .updateCompetency(id, {'days_taught': days}),
          ),
          const SizedBox(height: 12),
          TosSummaryRow(
            competencies: competencies,
            totalItems: tos.totalItems,
            timeUnit: tos.timeUnit,
          ),
          TosMissingPointsBanner(
            competencies: competencies,
            tos: tos,
          ),
        ],
      ],
    );
  }
}
