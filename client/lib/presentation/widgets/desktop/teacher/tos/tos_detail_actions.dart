import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/presentation/pages/desktop/teacher/tos/tos_edit_page.dart';
import 'package:likha/presentation/providers/tos_provider.dart';
import 'package:likha/presentation/widgets/shared/dialogs/app_dialogs.dart';

class TosDetailActions extends ConsumerWidget {
  final TableOfSpecifications tos;
  final List<TosCompetency> competencies;
  final String tosId;

  const TosDetailActions({
    super.key,
    required this.tos,
    required this.competencies,
    required this.tosId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.tonalIcon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditTosPage(tos: tos),
            ),
          ).then((_) {
            ref.read(tosProvider.notifier).loadTosDetail(tosId);
          }),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Edit'),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => AppDialogs.showDestructive(
            context: context,
            title: 'Delete TOS',
            body:
                'This will permanently delete this Table of Specifications and all its competencies.',
            confirmLabel: 'Delete',
            onConfirm: () async {
              await ref.read(tosProvider.notifier).deleteTos(tosId);
              if (context.mounted) Navigator.pop(context);
            },
          ),
          icon: const Icon(Icons.delete_outline_rounded,
              color: AppColors.semanticError),
          tooltip: 'Delete',
        ),
      ],
    );
  }
}
