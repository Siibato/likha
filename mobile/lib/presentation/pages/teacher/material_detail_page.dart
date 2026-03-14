import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/utils/snackbar_utils.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';
import 'package:likha/presentation/providers/auth_provider.dart';
import 'package:likha/presentation/providers/learning_material_provider.dart';
import 'package:likha/presentation/widgets/styled_dialog.dart';
import 'package:likha/presentation/pages/shared/widgets/dialogs/app_dialogs.dart';
import 'package:open_file/open_file.dart';

class MaterialDetailPage extends ConsumerStatefulWidget {
  final String materialId;

  const MaterialDetailPage({super.key, required this.materialId});

  @override
  ConsumerState<MaterialDetailPage> createState() => _MaterialDetailPageState();
}

class _MaterialDetailPageState extends ConsumerState<MaterialDetailPage> {
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

  /// Open file with system default app
  Future<void> _openFile(MaterialFile file) async {
    if (file.localPath == null || file.localPath!.isEmpty) {
      // File path not available, offer to download
      if (!mounted) return;
      context.showWarningSnackBar('File not cached. Downloading...', durationMs: 2000);
      await _saveFile(file);
      return;
    }

    try {
      await OpenFile.open(file.localPath!);
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Error opening file: $e');
    }
  }

  /// Download file via provider (datasource handles caching)
  Future<void> _saveFile(MaterialFile file) async {
    if (mounted) {
      context.showInfoSnackBar('Downloading ${file.fileName}...', durationMs: 3000);
    }

    // Provider's downloadFile() handles the download and calls loadMaterialDetail()
    // to update file.localPath in the UI state
    await ref.read(learningMaterialProvider.notifier).downloadFile(file.id);

    if (!mounted) return;

    // Check if download succeeded by looking at provider state
    final providerState = ref.read(learningMaterialProvider);
    if (providerState.error != null) {
      context.showErrorSnackBar('Failed to download file', durationMs: 3000);
    } else {
      context.showSuccessSnackBar('✓ Downloaded: ${file.fileName}', durationMs: 3000);
    }
  }

  Future<void> _downloadAllFiles() async {
    final material = ref.read(learningMaterialProvider).currentMaterial;
    if (material == null || material.files.isEmpty) return;

    final toDownload = material.files.where((f) => !f.isCached).toList();
    if (toDownload.isEmpty) return;

    int downloadedCount = 0;
    final total = toDownload.length;

    for (final file in toDownload) {
      downloadedCount++;

      if (mounted) {
        context.showInfoSnackBar('Downloading $downloadedCount of $total: ${file.fileName}', durationMs: 60000);
      }

      await _saveFile(file);

      if (!mounted) return;
    }

    if (!mounted) return;
    context.showSuccessSnackBar('Downloaded $downloadedCount file(s)', durationMs: 3000);
  }

  void _deleteFile(MaterialFile file) {
    AppDialogs.showDestructive(
      context: context,
      title: 'Delete File',
      body: 'Are you sure you want to delete "${file.fileName}"?',
      confirmLabel: 'Delete',
      onConfirm: () => ref.read(learningMaterialProvider.notifier).deleteFile(file.id, widget.materialId),
    );
  }

  void _confirmDeleteMaterial() {
    final title = ref.read(learningMaterialProvider).currentMaterial?.title ?? 'this module';
    showDialog(
      context: context,
      builder: (ctx) => StyledDialog(
        title: 'Delete Module',
        subtitle: 'This action cannot be undone',
        content: Text(
          'Are you sure you want to permanently delete "$title" and all of its contents?',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF666666),
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
              ref.read(learningMaterialProvider.notifier).deleteMaterial(widget.materialId);
            },
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

    // Compute cache status
    final allCached = material != null && material.files.isNotEmpty && material.files.every((f) => f.isCached);
    final uncachedFiles = material != null ? material.files.where((f) => !f.isCached).toList() : <MaterialFile>[];

    ref.listen<LearningMaterialState>(learningMaterialProvider, (prev, next) {
      // Intercept delete success before showing snackbar
      if (next.successMessage == 'Material deleted successfully') {
        ref.read(learningMaterialProvider.notifier).clearMessages();
        if (mounted) Navigator.pop(context, true);
        return;
      }

      if (next.error != null && prev?.error != next.error) {
        context.showErrorSnackBar(next.error!);
        ref.read(learningMaterialProvider.notifier).clearMessages();
      }
      if (next.successMessage != null && prev?.successMessage != next.successMessage) {
        context.showSuccessSnackBar(next.successMessage!);
        ref.read(learningMaterialProvider.notifier).clearMessages();
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
        actions: [
          if (isTeacher)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') _confirmDeleteMaterial();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'delete', child: Text('Delete Module')),
              ],
            ),
        ],
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

                  // Content Text
                  if (material.contentText != null && material.contentText!.isNotEmpty) ...[
                    Text(
                      material.contentText!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF333333),
                        height: 1.6,
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
                      else if (material.files.isNotEmpty && !allCached)
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
                          label: Text(
                            uncachedFiles.length == material.files.length
                                ? 'Download All'
                                : 'Download ${uncachedFiles.length} remaining',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
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
                                  icon: file.isCached
                                      ? const Icon(Icons.folder_open_rounded)
                                      : const Icon(Icons.download_rounded),
                                  color: state.isLoading
                                      ? const Color(0xFFCCCCCC)
                                      : const Color(0xFF2B2B2B),
                                  tooltip: state.isLoading
                                      ? 'Downloading...'
                                      : (file.isCached ? 'Open file' : 'Save file'),
                                  onPressed: state.isLoading
                                      ? null
                                      : () => file.isCached
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
                                    onPressed: state.isLoading ? null : () => _deleteFile(file),
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
