import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/logging/page_logger.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/widgets/shared/forms/form_message.dart';
import 'package:likha/presentation/providers/learning_material_provider.dart';
import 'package:likha/presentation/widgets/shared/dialogs/app_dialogs.dart';
import 'package:likha/presentation/widgets/shared/dialogs/styled_dialog.dart';
import 'package:likha/presentation/widgets/mobile/teacher/material/edit_material_dialog.dart';
import 'package:likha/presentation/widgets/mobile/teacher/material/material_attachments_card.dart';
import 'package:likha/presentation/widgets/mobile/teacher/material/material_body_card.dart';
import 'package:likha/presentation/widgets/mobile/teacher/material/material_info_card.dart';
import 'package:likha/presentation/widgets/mobile/teacher/material/material_upload_progress_card.dart';
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
    PageLogger.instance.log('MaterialDetailPage initState - materialId: ${widget.materialId}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PageLogger.instance.log('Now calling loadMaterialDetail()');
      ref.read(learningMaterialProvider.notifier).loadMaterialDetail(widget.materialId);
    });
  }

  void _editMaterial(dynamic material) {
    showDialog(
      context: context,
      builder: (_) => EditMaterialDialog(material: material),
    );
  }

  void _showMoreOptions(dynamic material) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Edit Module'),
              onTap: () {
                Navigator.pop(ctx);
                _editMaterial(material);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.semanticError),
              title: const Text('Delete Module', style: TextStyle(color: AppColors.semanticError)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteMaterial();
              },
            ),
          ],
        ),
      ),
    );
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
    await ref.read(learningMaterialProvider.notifier).downloadFile(file.id);

    if (!mounted) return;

    final providerState = ref.read(learningMaterialProvider);
    if (providerState.error != null) {
      setState(() => _formError = 'Failed to download file');
    } else {
      setState(() => _formError = null);
    }
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
            color: AppColors.foregroundSecondary,
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
      backgroundColor: AppColors.backgroundSecondary,
      body: SafeArea(
        child: state.isLoading && material == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.accentCharcoal, strokeWidth: 2.5),
              )
            : state.error != null && material == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.foregroundLight),
                        const SizedBox(height: 16),
                        const Text('Failed to load module', style: TextStyle(fontSize: 16, color: AppColors.foregroundSecondary)),
                        const SizedBox(height: 24),
                        OutlinedButton(
                          onPressed: () => ref.read(learningMaterialProvider.notifier).loadMaterialDetail(widget.materialId),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Stack(
                          children: [
                            ClassSectionHeader(
                              title: material?.title ?? 'Module Details',
                              showBackButton: true,
                            ),
                            Positioned(
                              right: 24,
                              top: 24,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundTertiary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.more_vert_rounded,
                                    color: AppColors.foregroundDark,
                                    size: 24,
                                  ),
                                  onPressed: () => _showMoreOptions(material),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.all(24),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            // Form Error Display
                            FormMessage(
                              message: _formError,
                              severity: MessageSeverity.error,
                            ),
                            if (_formError != null) const SizedBox(height: 12),

                            // Module Info Card
                            MaterialInfoCard(
                              title: material!.title,
                              description: material.description,
                              fileCount: material.files.length,
                              updatedAt: material.updatedAt,
                              needsSync: material.needsSync,
                            ),
                            const SizedBox(height: 16),

                            // Module Content Section
                            if (material.contentText != null && material.contentText!.isNotEmpty) ...[
                              MaterialBodyCard(contentText: material.contentText),
                              const SizedBox(height: 16),
                            ],

                            // Upload progress bar
                            if (state.isLoading && state.currentUploadFileName != null) ...[
                              MaterialUploadProgressCard(
                                fileName: state.currentUploadFileName!,
                                progress: state.uploadProgress,
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Attachments Section
                            if (material.files.isNotEmpty)
                              MaterialAttachmentsCard(
                                files: material.files,
                                isTeacher: true,
                                isLoading: state.isLoading,
                                allCached: false,
                                uncachedCount: 0,
                                onUploadFile: _uploadFile,
                                onOpenFile: _openFile,
                                onSaveFile: _saveFile,
                                onDeleteFile: _deleteFile,
                              ),

                            const SizedBox(height: 40),
                          ]),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

}
