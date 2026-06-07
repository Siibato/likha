import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';
import 'package:likha/presentation/widgets/shared/cards/base_card.dart';
import 'package:likha/presentation/widgets/shared/primitives/card_icon_slot.dart';

class MaterialAttachmentsCard extends StatelessWidget {
  final List<MaterialFile> files;
  final bool isTeacher;
  final bool isLoading;
  final bool allCached;
  final int uncachedCount;
  final VoidCallback? onUploadFile;
  final Function(MaterialFile) onOpenFile;
  final Function(MaterialFile) onSaveFile;
  final VoidCallback? onDownloadAllFiles;
  final Function(MaterialFile) onDeleteFile;

  const MaterialAttachmentsCard({
    super.key,
    required this.files,
    required this.isTeacher,
    required this.isLoading,
    required this.allCached,
    required this.uncachedCount,
    this.onUploadFile,
    required this.onOpenFile,
    required this.onSaveFile,
    this.onDownloadAllFiles,
    required this.onDeleteFile,
  });

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Attachments',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.foregroundDark,
                  letterSpacing: -0.4,
                ),
              ),
              if (isTeacher)
                FilledButton(
                  onPressed: isLoading ? null : onUploadFile,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentCharcoal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'Upload',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 12),
          ...files.asMap().entries.map((entry) {
            final file = entry.value;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CardIconSlot.sm(
                icon: Icons.insert_drive_file_rounded,
              ),
              title: Text(
                file.fileName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentCharcoal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                _formatFileSize(file.fileSize),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.foregroundTertiary,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: file.isCached
                        ? const Icon(Icons.folder_open_rounded)
                        : const Icon(Icons.download_rounded, color: AppColors.accentCharcoal),
                    onPressed: isLoading
                        ? null
                        : () => file.isCached
                            ? onOpenFile(file)
                            : onSaveFile(file),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.semanticError),
                    onPressed: isLoading ? null : () => onDeleteFile(file),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
