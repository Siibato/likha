import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/controllers/teacher/material/material_detail_controller.dart';
import 'package:likha/presentation/providers/learning_material_provider.dart';
import 'package:likha/presentation/widgets/mobile/teacher/material/edit_material_dialog.dart';
import 'package:likha/presentation/widgets/shared/dialogs/styled_dialog.dart';

class MaterialDetailOptionsSheet extends ConsumerWidget {
  final dynamic material;
  final String materialId;
  final MaterialDetailController controller;

  const MaterialDetailOptionsSheet({
    super.key,
    required this.material,
    required this.materialId,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_rounded),
            title: const Text('Edit Module'),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (_) => EditMaterialDialog(
                  material: material,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.semanticError,
            ),
            title: const Text(
              'Delete Module',
              style: TextStyle(
                color: AppColors.semanticError,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(context, ref);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    final title = ref.read(learningMaterialProvider).currentMaterial?.title ??
        'this module';
    showDialog(
      context: context,
      builder: (ctx) => StyledDialog(
        title: 'Delete Module',
        subtitle: 'This action cannot be undone',
        content: Text(
          'Are you sure you want to permanently delete "$title" and all of its contents?',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.foregroundSecondary,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          StyledDialogAction(
            label: 'Cancel',
            onPressed: () => Navigator.pop(ctx),
          ),
          StyledDialogAction(
            label: 'Delete',
            isPrimary: true,
            isDestructive: true,
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteMaterial(
                materialId: materialId,
                notifier: ref.read(learningMaterialProvider.notifier),
              );
            },
          ),
        ],
      ),
    );
  }
}
