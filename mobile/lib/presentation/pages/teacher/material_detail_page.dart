import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';
import 'package:likha/presentation/providers/auth_provider.dart';
import 'package:likha/presentation/providers/learning_material_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class MaterialDetailPage extends ConsumerStatefulWidget {
  final String materialId;

  const MaterialDetailPage({super.key, required this.materialId});

  @override
  ConsumerState<MaterialDetailPage> createState() => _MaterialDetailPageState();
}

class _MaterialDetailPageState extends ConsumerState<MaterialDetailPage> {
  final Map<String, bool> _fileExistsMap = {};

  @override
  void initState() {
    super.initState();
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('[PAGE_INIT] MaterialDetailPage initState');
    debugPrint('[PAGE_INIT] materialId: ${widget.materialId}');
    debugPrint('[PAGE_INIT] Scheduling loadMaterialDetail()...');
    debugPrint('═══════════════════════════════════════════════════════════');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('[PAGE_INIT] ▶ Now calling loadMaterialDetail()');
      ref.read(learningMaterialProvider.notifier).loadMaterialDetail(widget.materialId);
    });
  }

  /// Check all files in the material to see which ones exist on device
  /// Populates _fileExistsMap with results and triggers a setState to update the UI
  Future<void> _checkAllFilesExist(List<MaterialFile> files) async {
    final results = <String, bool>{};
    for (final file in files) {
      final found = await _findFileOnDevice(file);
      results[file.id] = found != null;
    }
    if (mounted) {
      setState(() {
        _fileExistsMap
          ..clear()
          ..addAll(results);
      });
    }
  }

  Future<void> _uploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'mp4', 'mp3', 'jpg', 'png', 'gif'],
    );

    if (result != null && result.files.single.path != null) {
      await ref.read(learningMaterialProvider.notifier).uploadFile(
            materialId: widget.materialId,
            filePath: result.files.single.path!,
            fileName: result.files.single.name,
          );
    }
  }

  /// Compute device filename from material file: originalName-[first10charsOfId].ext
  String _deviceFileName(MaterialFile file) {
    final shortId = file.id.replaceAll('-', '').substring(0, 10);
    final dotIndex = file.fileName.lastIndexOf('.');
    if (dotIndex == -1) return '${file.fileName}-$shortId';
    final name = file.fileName.substring(0, dotIndex);
    final ext = file.fileName.substring(dotIndex); // includes the dot
    return '$name-$shortId$ext';
  }

  /// Search directory for file by ID suffix (non-recursive)
  File? _searchDirForFile(Directory dir, String fileId) {
    final shortId = fileId.replaceAll('-', '').substring(0, 10);
    debugPrint('[SEARCH] Searching in: ${dir.path}');
    debugPrint('[SEARCH] Looking for files with suffix: -$shortId.');

    try {
      final entries = dir.listSync(recursive: false);
      debugPrint('[SEARCH] Found ${entries.length} entries in directory');

      for (final entry in entries) {
        if (entry is File) {
          final fileName = entry.path.split('/').last;
          debugPrint('[SEARCH]   Checking file: $fileName');

          if (entry.path.contains('-$shortId.')) {
            debugPrint('[SEARCH] ✓ MATCH FOUND: ${entry.path}');
            return entry;
          }
        }
      }

      debugPrint('[SEARCH] No matching files found in ${dir.path}');
    } catch (e) {
      debugPrint('[SEARCH] Error searching directory: $e');
    }
    return null;
  }

  /// Find file on device by searching Downloads, then app Documents by ID suffix
  Future<File?> _findFileOnDevice(MaterialFile file) async {
    // 1. Search Downloads directory
    final downloadsDir = await getDownloadsDirectory();
    if (downloadsDir != null) {
      final found = _searchDirForFile(downloadsDir, file.id);
      if (found != null) return found;
    }

    // 2. Search app Documents directory
    final docsDir = await getApplicationDocumentsDirectory();
    return _searchDirForFile(docsDir, file.id);
  }

  /// Open file with system default app
  Future<void> _openFile(MaterialFile file) async {
    final found = await _findFileOnDevice(file);

    if (found != null) {
      try {
        await OpenFile.open(found.path);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: $e'),
            backgroundColor: const Color(0xFFEF5350),
          ),
        );
      }
      return;
    }

    // File not found — re-download
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File not found on device. Re-downloading...'),
        backgroundColor: Color(0xFFFF9800),
        duration: Duration(seconds: 2),
      ),
    );
    await _saveFile(file);
  }

  /// Auto-save file to Documents folder
  Future<void> _saveFile(MaterialFile file) async {
    try {
      final deviceName = _deviceFileName(file);

      // Show download started indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloading ${file.fileName}...'),
            backgroundColor: const Color(0xFF2B2B2B),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Download bytes from server
      final bytes = await ref.read(learningMaterialProvider.notifier)
          .downloadFile(file.id);

      if (bytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to download file'),
            backgroundColor: Color(0xFFEF5350),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Save to Documents folder
      final appDocsDir = await getApplicationDocumentsDirectory();
      final savePath = '${appDocsDir.path}/$deviceName';

      try {
        await File(savePath).writeAsBytes(bytes);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: const Color(0xFFEF5350),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Step 4: Refresh file existence map and show success
      final material = ref.read(learningMaterialProvider).currentMaterial;
      if (material != null && mounted) {
        await _checkAllFilesExist(material.files);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Saved: ${file.fileName}'),
          backgroundColor: const Color(0xFF4CAF50),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFEF5350),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _downloadAllFiles() async {
    final material = ref.read(learningMaterialProvider).currentMaterial;
    if (material == null || material.files.isEmpty) return;

    int downloadedCount = 0;
    final totalFiles = material.files.length;

    for (final file in material.files) {
      downloadedCount++;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloading $downloadedCount of $totalFiles: ${file.fileName}'),
            backgroundColor: const Color(0xFF2B2B2B),
            duration: const Duration(seconds: 60),
          ),
        );
      }

      await _saveFile(file);

      if (!mounted) return;
    }

    // Refresh all files after batch download completes
    if (mounted && material.files.isNotEmpty) {
      await _checkAllFilesExist(material.files);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloaded $downloadedCount file(s)'),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _deleteFile(String fileId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete File'),
        content: const Text('Are you sure you want to delete this file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(learningMaterialProvider.notifier).deleteFile(fileId, widget.materialId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(learningMaterialProvider);
    final material = state.currentMaterial;
    final user = ref.watch(authProvider).user;
    final isTeacher = user?.role == 'teacher' || user?.role == 'admin';

    ref.listen<LearningMaterialState>(learningMaterialProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: const Color(0xFFEF5350),
          ),
        );
        ref.read(learningMaterialProvider.notifier).clearMessages();
      }
      if (next.successMessage != null && prev?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
        ref.read(learningMaterialProvider.notifier).clearMessages();
      }
      // Check file existence when material finishes loading
      if (!next.isLoading && next.currentMaterial != null) {
        _checkAllFilesExist(next.currentMaterial!.files);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2B2B2B)),
        title: Text(
          material?.title ?? 'Module Detail',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B2B),
          ),
        ),
      ),
      body: material == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2B2B2B)))
          : RefreshIndicator(
              onRefresh: () => ref.read(learningMaterialProvider.notifier).loadMaterialDetail(widget.materialId),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Title
                  Text(
                    material.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2B2B2B),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  if (material.description != null && material.description!.isNotEmpty) ...[
                    Text(
                      material.description!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF666666),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Files Section
                  Row(
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
                          onPressed: state.isLoading ? null : _uploadFile,
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
                      else if (material.files.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: state.isLoading ? null : _downloadAllFiles,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2B2B2B),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Text('Download All', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // File List
                  if (material.files.isEmpty)
                    Container(
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
                  else
                    ...material.files.map((file) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.insert_drive_file_rounded, color: Color(0xFF2B2B2B)),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  file.fileName,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                                if (state.isLoading)
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
                            subtitle: Text('${(file.fileSize / 1024 / 1024).toStringAsFixed(2)} MB'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: (_fileExistsMap[file.id] ?? false)
                                      ? const Icon(Icons.folder_open_rounded)
                                      : const Icon(Icons.download_rounded),
                                  color: state.isLoading
                                      ? const Color(0xFFCCCCCC)
                                      : const Color(0xFF2B2B2B),
                                  tooltip: state.isLoading
                                      ? 'Downloading...'
                                      : ((_fileExistsMap[file.id] ?? false) ? 'Open file' : 'Save file'),
                                  onPressed: state.isLoading
                                      ? null
                                      : () => (_fileExistsMap[file.id] ?? false)
                                          ? _openFile(file)
                                          : _saveFile(file),
                                ),
                                if (isTeacher)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded),
                                    color: state.isLoading
                                        ? const Color(0xFFCCCCCC)
                                        : const Color(0xFFEF5350),
                                    tooltip:
                                        state.isLoading ? 'Downloading...' : 'Delete file',
                                    onPressed: state.isLoading ? null : () => _deleteFile(file.id),
                                  ),
                              ],
                            ),
                          ),
                        );
                    }),
                ],
              ),
            ),
    );
  }
}
