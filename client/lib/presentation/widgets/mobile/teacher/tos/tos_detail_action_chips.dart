import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/presentation/pages/mobile/teacher/tos/tos_edit_page.dart';
import 'package:likha/presentation/providers/tos_provider.dart';
import 'package:likha/presentation/widgets/mobile/teacher/tos/tos_action_chip.dart';
import 'package:likha/presentation/widgets/shared/dialogs/app_dialogs.dart';

class TosDetailActionChips extends ConsumerWidget {
  final TableOfSpecifications tos;
  final List<TosCompetency> competencies;

  const TosDetailActionChips({
    super.key,
    required this.tos,
    required this.competencies,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TosActionChip(
          icon: Icons.edit_outlined,
          label: 'Edit',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditTosPage(tos: tos),
            ),
          ),
        ),
        const SizedBox(width: 8),
        TosActionChip(
          icon: Icons.delete_outline_rounded,
          label: 'Delete',
          color: AppColors.semanticError,
          onTap: () => AppDialogs.showDestructive(
            context: context,
            title: 'Delete TOS',
            body:
                'This will permanently delete this Table of Specifications and all its competencies.',
            confirmLabel: 'Delete',
            onConfirm: () async {
              await ref.read(tosProvider.notifier).deleteTos(tos.id);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ),
      ],
    );
  }
}
