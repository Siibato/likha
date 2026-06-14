import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/controllers/teacher/tos/tos_detail_controller.dart';
import 'package:likha/presentation/providers/tos_provider.dart';
import 'package:likha/presentation/widgets/mobile/teacher/tos/tos_outlined_button.dart';
import 'package:likha/presentation/widgets/shared/dialogs/add_competency_dialog.dart';

class TosAddCompetencyButton extends ConsumerWidget {
  final String tosId;
  final String timeUnit;
  final TosDetailController controller;

  const TosAddCompetencyButton({
    super.key,
    required this.tosId,
    required this.timeUnit,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TosOutlinedButton(
      icon: Icons.add,
      label: 'Add Competency',
      onTap: () {
        controller.prepareAddCompetency();
        final unitLabel = timeUnit == 'hours' ? 'Hours' : 'Days';
        showDialog(
          context: context,
          builder: (ctx) => AddCompetencyDialog(
            competencyController: controller.competencyController,
            timeUnitsTaughtController: controller.timeUnitsTaughtController,
            unitLabel: unitLabel,
            onAdd: () {
              final text = controller.competencyController.text.trim();
              if (text.isNotEmpty) {
                ref.read(tosProvider.notifier).addCompetency(
                  tosId,
                  {
                    'competency_text': text,
                    'days_taught': int.tryParse(
                            controller.timeUnitsTaughtController.text.trim()) ??
                        1,
                    'order_index': ref.read(tosProvider).competencies.length,
                  },
                );
              }
            },
          ),
        );
      },
    );
  }
}
