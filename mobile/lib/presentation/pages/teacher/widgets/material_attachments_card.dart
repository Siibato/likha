import 'package:flutter/material.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Attachments header with action button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Attachments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2B2B2B),
                ),
              ),
              if (isTeacher)
                ElevatedButton.icon(
                  onPressed: isLoading ? null : onUploadFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B2B2B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.upload_file_rounded, size: 18),
                  label: const Text('Upload', style: TextStyle(fontWeight: FontWeight.w600)),
                )
              else if (files.isNotEmpty && !allCached)
                ElevatedButton.icon(
                  onPressed: isLoading ? null : onDownloadAllFiles,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B2B2B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text(
                    uncachedCount == files.length
                        ? 'Download All'
                        : 'Download $uncachedCount remaining',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
        // File list or empty state
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: files.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: const Center(
                    child: Text(
                      'No attachments',
                      style: TextStyle(color: Color(0xFF999999)),
                    ),
                  ),
                )
              : Column(
                  children: files.asMap().entries.map((entry) {
                    final index = entry.key;
                    final file = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < files.length - 1 ? 8 : 0,
                      ),
                      child: Card(
                        margin: EdgeInsets.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.insert_drive_file_rounded,
                            color: Color(0xFF2B2B2B),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  file.fileName,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isLoading)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF2B2B2B),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            '${(file.fileSize / 1024 / 1024).toStringAsFixed(2)} MB',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: file.isCached
                                    ? const Icon(Icons.folder_open_rounded)
                                    : const Icon(Icons.download_rounded),
                                color: isLoading
                                    ? const Color(0xFFCCCCCC)
                                    : const Color(0xFF2B2B2B),
                                tooltip: isLoading
                                    ? 'Downloading...'
                                    : (file.isCached ? 'Open file' : 'Save file'),
                                onPressed: isLoading
                                    ? null
                                    : () => file.isCached
                                        ? onOpenFile(file)
                                        : onSaveFile(file),
                              ),
                              if (isTeacher)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded),
                                  color: isLoading
                                      ? const Color(0xFFCCCCCC)
                                      : const Color(0xFFEF5350),
                                  tooltip: isLoading ? 'Downloading...' : 'Delete file',
                                  onPressed: isLoading ? null : () => onDeleteFile(file),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}
