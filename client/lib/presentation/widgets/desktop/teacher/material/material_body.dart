import 'package:flutter/material.dart';

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

  const MaterialBody({
    super.key,
    required this.material,
    required this.isLoading,
    required this.onHandleFile,
    required this.onDeleteFile,
    required this.onUploadFile,
  });

  @override
  Widget build(BuildContext context) {
    final hasDescription = material.description != null &&
        (material.description as String).isNotEmpty;
    final hasContentText = material.contentText != null &&
        (material.contentText as String).isNotEmpty;
    final hasTextContent = hasDescription || hasContentText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MaterialInfoChips(material: material),
        const SizedBox(height: 20),
        if (hasTextContent)
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
                      ),
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
          )
        else
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: MaterialFilesPanel(
                material: material,
                isLoading: isLoading,
                onHandleFile: onHandleFile,
                onDeleteFile: onDeleteFile,
                onUploadFile: onUploadFile,
              ),
            ),
          ),
      ],
    );
  }
}
