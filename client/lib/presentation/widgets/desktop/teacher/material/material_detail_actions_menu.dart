import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/controllers/teacher/material/material_detail_controller.dart';
import 'package:likha/presentation/providers/learning_material_provider.dart';
import 'package:likha/presentation/widgets/desktop/teacher/material/edit_material_dialog.dart';
import 'package:likha/presentation/widgets/shared/dialogs/app_dialogs.dart';

class MaterialDetailActionsMenu extends ConsumerWidget {
  final dynamic material;
  final String materialId;
  final MaterialDetailController controller;

  const MaterialDetailActionsMenu({
    super.key,
    required this.material,
    required this.materialId,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded,
          color: AppColors.foregroundDark),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            showDialog(
              context: context,
              builder: (_) => EditMaterialDialog(
                materialId: material.id,
                initialTitle: material.title,
                initialContent: material.contentText,
              ),
            );
            break;
          case 'delete':
            _confirmDelete(context, ref);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded,
                  size: 18, color: AppColors.foregroundSecondary),
              SizedBox(width: 12),
              Text('Edit'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_rounded,
                  size: 18, color: AppColors.semanticError),
              SizedBox(width: 12),
              Text('Delete',
                  style: TextStyle(color: AppColors.semanticError)),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final title = ref.read(learningMaterialProvider).currentMaterial?.title ??
        'this module';
    AppDialogs.showDestructive(
      context: context,
      title: 'Delete Module',
      body:
          'Are you sure you want to permanently delete "$title" and all of its contents? This cannot be undone.',
      confirmLabel: 'Delete',
      onConfirm: () => controller.deleteMaterial(
        materialId: materialId,
        notifier: ref.read(learningMaterialProvider.notifier),
      ),
    );
  }
}
