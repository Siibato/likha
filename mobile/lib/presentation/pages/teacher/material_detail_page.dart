import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/form_message.dart';
import 'package:likha/presentation/pages/teacher/widgets/material_attachments_card.dart';
import 'package:likha/presentation/pages/teacher/widgets/material_content_card.dart';
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
  String? _formError;

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
      setState(() => _formError = 'File not cached. Downloading...');
      await _saveFile(file);
      return;
    }

    try {
      await OpenFile.open(file.localPath!);
    } catch (e) {
      if (!mounted) return;
      setState(() => _formError = 'Error opening file: $e');
    }
  }

  /// Download file via provider (datasource handles caching)
  Future<void> _saveFile(MaterialFile file) async {
    // Provider's downloadFile() handles the download and calls loadMaterialDetail()
    // to update file.localPath in the UI state
    await ref.read(learningMaterialProvider.notifier).downloadFile(file.id);

    if (!mounted) return;

    // Check if download succeeded by looking at provider state
    final providerState = ref.read(learningMaterialProvider);
    if (providerState.error != null) {
      setState(() => _formError = 'Failed to download file');
    } else {
      setState(() => _formError = null);
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

      await _saveFile(file);

      if (!mounted) return;
    }

    if (!mounted) return;
    setState(() => _formError = null);
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
        setState(() => _formError = AppErrorMapper.toUserMessage(next.error));
        ref.read(learningMaterialProvider.notifier).clearMessages();
      }
      if (next.successMessage != null && prev?.successMessage != next.successMessage) {
        setState(() => _formError = null);
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
                  // Form Error Display
                  FormMessage(
                    message: _formError,
                    severity: MessageSeverity.error,
                  ),
                  if (_formError != null) const SizedBox(height: 12),

                  // Content card (title and contentText)
                  MaterialContentCard(
                    title: material.title,
                    contentText: material.contentText,
                  ),
                  const SizedBox(height: 24),

                  // Attachments card (only show if there are files or user is teacher)
                  if (material.files.isNotEmpty || isTeacher)
                    MaterialAttachmentsCard(
                      files: material.files,
                      isTeacher: isTeacher,
                      isLoading: state.isLoading,
                      allCached: allCached,
                      uncachedCount: uncachedFiles.length,
                      onUploadFile: _uploadFile,
                      onOpenFile: _openFile,
                      onSaveFile: _saveFile,
                      onDownloadAllFiles: _downloadAllFiles,
                      onDeleteFile: _deleteFile,
                    ),
                ],
              ),
            ),
    );
  }
}
