import 'package:flutter/material.dart';

import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/desktop/teacher/material/material_content_section.dart';
import 'package:likha/presentation/widgets/desktop/teacher/material/material_content_text_section.dart';
import 'package:likha/presentation/widgets/desktop/teacher/material/material_files_panel.dart';
import 'package:likha/presentation/widgets/desktop/teacher/material/material_info_chips.dart';

/// Desktop body layout for the material detail page.
class MaterialBody extends StatelessWidget {
  final dynamic material;
  final bool isLoading;
  final void Function(dynamic file) onHandleFile;
  final void Function(dynamic file) onDeleteFile;
  final VoidCallback onUploadFile;
  final VoidCallback onEdit;

  const MaterialBody({
    super.key,
    required this.material,
    required this.isLoading,
    required this.onHandleFile,
    required this.onDeleteFile,
    required this.onUploadFile,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final hasDescription = material.description != null &&
        (material.description as String).isNotEmpty;
    final hasContentText = material.contentText != null &&
        (material.contentText as String).isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MaterialInfoChips(material: material),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasDescription) ...[
                    MaterialContentSection(
                      heading: 'Description',
                      text: material.description as String,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (hasContentText)
                    MaterialContentTextSection(
                      contentText: material.contentText as String,
                      onEdit: onEdit,
                    )
                  else
                    _EmptyContentCard(onEdit: onEdit),
                ],
              ),
            ),
            const SizedBox(width: 24),
            SizedBox(
              width: 350,
              child: MaterialFilesPanel(
                material: material,
                isLoading: isLoading,
                onHandleFile: onHandleFile,
                onDeleteFile: onDeleteFile,
                onUploadFile: onUploadFile,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyContentCard extends StatelessWidget {
  final VoidCallback onEdit;

  const _EmptyContentCard({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Content',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundDark,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderLight),
          const SizedBox(height: 12),
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    size: 32,
                    color: AppColors.foregroundSecondary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add Content',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foregroundSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
