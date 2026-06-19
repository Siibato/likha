import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/formatters.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';

/// Desktop attachments panel for the material detail page.
class MaterialFilesPanel extends StatelessWidget {
  final dynamic material;
  final bool isLoading;
  final void Function(MaterialFile file) onHandleFile;
  final void Function(MaterialFile file) onDeleteFile;
  final VoidCallback onUploadFile;

  const MaterialFilesPanel({
    super.key,
    required this.material,
    required this.isLoading,
    required this.onHandleFile,
    required this.onDeleteFile,
    required this.onUploadFile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attachments (${material.files.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foregroundDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderLight),
          const SizedBox(height: 12),
          if (material.files.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No attachments',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.foregroundTertiary,
                  ),
                ),
              ),
            )
          else
            ...material.files.map<Widget>((MaterialFile file) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.insert_drive_file_rounded,
                      size: 20,
                      color: AppColors.foregroundSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.fileName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.foregroundDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            Formatters.formatFileSize(file.fileSize),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.foregroundTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        kIsWeb
                            ? Icons.open_in_browser_rounded
                            : file.isCached
                                ? Icons.folder_open_rounded
                                : Icons.download_rounded,
                        size: 18,
                        color: AppColors.foregroundPrimary,
                      ),
                      onPressed:
                          isLoading ? null : () => onHandleFile(file),
                      tooltip: kIsWeb
                          ? 'Open in browser'
                          : file.isCached
                              ? 'Open'
                              : 'Download',
                      splashRadius: 18,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: AppColors.semanticError,
                      ),
                      onPressed:
                          isLoading ? null : () => onDeleteFile(file),
                      tooltip: 'Delete',
                      splashRadius: 18,
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : onUploadFile,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.foregroundDark,
                      ),
                    )
                  : const Icon(Icons.upload_file_rounded, size: 18),
              label: Text(isLoading ? 'Uploading...' : 'Upload File'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.foregroundDark,
                side: const BorderSide(color: AppColors.borderLight),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
