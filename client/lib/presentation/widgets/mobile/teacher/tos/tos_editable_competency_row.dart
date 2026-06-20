import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/presentation/controllers/teacher/tos/tos_detail_controller.dart';
import 'package:likha/presentation/providers/tos_provider.dart';
import 'package:likha/presentation/widgets/mobile/teacher/tos/tos_competency_row.dart';
import 'package:likha/presentation/widgets/shared/dialogs/app_dialogs.dart';
import 'package:likha/presentation/widgets/shared/dialogs/edit_competency_dialog.dart';

class TosEditableCompetencyRow extends ConsumerWidget {
  final TosCompetency competency;
  final int totalDays;
  final String timeUnit;
  final TosDetailController controller;

  const TosEditableCompetencyRow({
    super.key,
    required this.competency,
    required this.totalDays,
    required this.timeUnit,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TosCompetencyRow(
      competency: competency,
      totalDays: totalDays,
      timeUnit: timeUnit,
      onEdit: () => _showEditDialog(context, ref),
      onDelete: () => AppDialogs.showDestructive(
        context: context,
        title: 'Delete Competency',
        body: 'Remove this competency?',
        confirmLabel: 'Delete',
        onConfirm: () =>
            ref.read(tosProvider.notifier).deleteCompetency(competency.id),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    controller.prepareEditCompetency(competency);
    final unitLabel = timeUnit == 'hours' ? 'Hours' : 'Days';
    showDialog(
      context: context,
      builder: (ctx) => EditCompetencyDialog(
        competencyController: controller.editCompetencyController,
        daysTaughtController: controller.editDaysTaughtController,
        unitLabel: unitLabel,
        onSave: () {
          final text = controller.editCompetencyController.text.trim();
          final days =
              int.tryParse(controller.editDaysTaughtController.text.trim());
          if (text.isNotEmpty) {
            ref.read(tosProvider.notifier).updateCompetency(
              competency.id,
              {
                'competency_text': text,
                if (days != null) 'days_taught': days,
              },
            );
          }
        },
      ),
    );
  }
}
