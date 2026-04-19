import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/base_card.dart';
import 'package:likha/presentation/pages/shared/widgets/primitives/card_icon_slot.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/styled_button.dart';
import 'package:likha/presentation/utils/formatters.dart';

class AssignmentFilesCard extends StatelessWidget {
  final List files;
  final bool isReadOnly;
  final String? allowedFileTypes;
  final int? maxFileSizeMb;
  final VoidCallback onUploadPressed;
  final Function(String) onDeleteFile;

  const AssignmentFilesCard({
    super.key,
    required this.files,
    required this.isReadOnly,
    this.allowedFileTypes,
    this.maxFileSizeMb,
    required this.onUploadPressed,
    required this.onDeleteFile,
  });

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Files',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF202020),
              letterSpacing: -0.4,
            ),
          ),
          if (allowedFileTypes != null) ...[
            const SizedBox(height: 6),
            Text(
              'Allowed: $allowedFileTypes',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF999999),
              ),
            ),
          ],
          if (maxFileSizeMb != null) ...[
            const SizedBox(height: 2),
            Text(
              'Max size: $maxFileSizeMb MB',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF999999),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: const Color(0xFFF0F0F0),
          ),
          if (files.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...files.map((file) => _FileListTile(
                  fileName: file.fileName,
                  fileSize: file.fileSize,
                  isReadOnly: isReadOnly,
                  onDelete: () => onDeleteFile(file.id),
                )),
          ],
          if (!isReadOnly) ...[
            const SizedBox(height: 12),
            StyledButton(
              text: 'Upload File',
              variant: StyledButtonVariant.outlined,
              icon: Icons.upload_file_rounded,
              isLoading: false,
              onPressed: onUploadPressed,
            ),
          ],
        ],
      ),
    );
  }
}

class _FileListTile extends StatelessWidget {
  final String fileName;
  final int fileSize;
  final bool isReadOnly;
  final VoidCallback onDelete;

  const _FileListTile({
    required this.fileName,
    required this.fileSize,
    required this.isReadOnly,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CardIconSlot.sm(
        icon: Icons.attach_file_rounded,
        iconColor: AppColors.foregroundSecondary,
      ),
      title: Text(
        fileName,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2B2B2B),
        ),
      ),
      subtitle: Text(
        Formatters.formatFileSize(fileSize),
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF999999),
        ),
      ),
      trailing: isReadOnly
          ? null
          : IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFEA4335),
              ),
              onPressed: onDelete,
            ),
    );
  }
}