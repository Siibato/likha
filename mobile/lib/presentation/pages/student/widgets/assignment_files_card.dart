import 'package:flutter/material.dart';
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
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
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
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onUploadPressed,
                  icon: const Icon(
                    Icons.upload_file_rounded,
                    color: Color(0xFFFFBD59),
                  ),
                  label: const Text(
                    'Upload File',
                    style: TextStyle(
                      color: Color(0xFF2B2B2B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(
                      color: Color(0xFFE0E0E0),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
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
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.attach_file_rounded,
          color: Color(0xFF666666),
          size: 20,
        ),
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