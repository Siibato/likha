import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/logging/page_logger.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/widgets/shared/cards/base_card.dart';
import 'package:likha/presentation/widgets/shared/cards/markdown_display.dart';
import 'package:likha/presentation/widgets/shared/primitives/card_icon_slot.dart';
import 'package:likha/presentation/widgets/shared/primitives/status_badge.dart';
import 'package:likha/presentation/widgets/shared/primitives/info_chip.dart';
import 'package:likha/presentation/widgets/shared/forms/form_message.dart';
import 'package:likha/presentation/utils/formatters.dart';
import 'package:likha/presentation/widgets/shared/forms/rich_text_field.dart';
import 'package:likha/presentation/providers/learning_material_provider.dart';
import 'package:likha/presentation/widgets/shared/dialogs/styled_dialog.dart';
import 'package:likha/presentation/widgets/shared/dialogs/app_dialogs.dart';
import 'package:open_file/open_file.dart';

class MaterialDetailPage extends ConsumerStatefulWidget {
  final String materialId;

  const MaterialDetailPage({super.key, required this.materialId});

  @override
  ConsumerState<MaterialDetailPage> createState() => _MaterialDetailPageState();
}

class _MaterialDetailPageState extends ConsumerState<MaterialDetailPage> {
  String? _formError;
  String? _downloadingFileId;

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
      builder: (_) => _EditMaterialDialog(material: material),
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
    setState(() => _downloadingFileId = file.id);
    await ref.read(learningMaterialProvider.notifier).downloadFile(file.id);

    if (!mounted) return;
    setState(() => _downloadingFileId = null);

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

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
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
                            _buildInfoCard(material),
                            const SizedBox(height: 16),

                            // Module Content Section
                            if (material!.contentText != null && material.contentText!.isNotEmpty) ...[
                              _buildContentCard(material),
                              const SizedBox(height: 16),
                            ],

                            // Upload progress bar
                            if (state.isLoading && state.currentUploadFileName != null) ...[
                              _buildUploadProgressCard(state),
                              const SizedBox(height: 16),
                            ],

                            // Attachments Section
                            if (material.files.isNotEmpty) ...[
                              _buildAttachmentsCard(material, state.isLoading),
                            ],

                            const SizedBox(height: 40),
                          ]),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildInfoCard(dynamic material) {
    return BaseCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            material.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.accentCharcoal,
              letterSpacing: -0.5,
            ),
          ),
          if (material.description != null && material.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 12),
            Text(
              material.description!,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.accentCharcoal,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              InfoChip(
                icon: Icons.attach_file_rounded,
                label: '${material.files.length} file(s)',
              ),
              const SizedBox(width: 14),
              InfoChip(
                icon: Icons.schedule_rounded,
                label: 'Updated ${_formatDate(material.updatedAt)}',
              ),
            ],
          ),
          if (material.needsSync) ...[
            const SizedBox(height: 12),
            const StatusBadge(
              label: 'Pending sync',
              color: AppColors.foregroundTertiary,
              variant: BadgeVariant.outlined,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContentCard(dynamic material) {
    return BaseCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Content',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 12),
          MarkdownDisplay(content: material.contentText),
        ],
      ),
    );
  }

  Widget _buildUploadProgressCard(LearningMaterialState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: AppColors.accentCharcoal,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Uploading ${state.currentUploadFileName}...',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentCharcoal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(state.uploadProgress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentCharcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.uploadProgress > 0 ? state.uploadProgress : null,
              backgroundColor: AppColors.borderLight,
              color: AppColors.accentCharcoal,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsCard(dynamic material, bool isLoading) {
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
              FilledButton(
                onPressed: isLoading ? null : _uploadFile,
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
          ...material.files.asMap().entries.map((entry) {
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
                formatFileSize(file.fileSize),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.foregroundTertiary,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_downloadingFileId == file.id)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.accentCharcoal,
                        strokeWidth: 2,
                      ),
                    )
                  else
                    IconButton(
                      icon: file.isCached
                          ? const Icon(Icons.folder_open_rounded)
                          : const Icon(Icons.download_rounded, color: AppColors.accentCharcoal),
                      onPressed: (isLoading || _downloadingFileId != null)
                          ? null
                          : () => file.isCached
                              ? _openFile(file)
                              : _saveFile(file),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.semanticError),
                    onPressed: (isLoading || _downloadingFileId != null) ? null : () => _deleteFile(file),
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

/// Dialog to edit a learning material's title, description, and content.
class _EditMaterialDialog extends ConsumerStatefulWidget {
  final dynamic material;

  const _EditMaterialDialog({required this.material});

  @override
  ConsumerState<_EditMaterialDialog> createState() =>
      _EditMaterialDialogState();
}

class _EditMaterialDialogState extends ConsumerState<_EditMaterialDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final FleatherController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.material.title);
    _descController =
        TextEditingController(text: widget.material.description ?? '');

    // Initialize content controller with existing content
    if (widget.material.contentText != null &&
        widget.material.contentText!.isNotEmpty) {
      try {
        final doc = ParchmentDocument.fromJson(
            jsonDecode(widget.material.contentText));
        _contentController = FleatherController(document: doc);
      } catch (e) {
        _contentController = FleatherController();
      }
    } else {
      _contentController = FleatherController();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    final newTitle = _titleController.text.trim();
    if (newTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    Navigator.pop(context);

    final contentPlainText =
        _contentController.document.toPlainText().trim();
    final contentJson = contentPlainText.isEmpty
        ? null
        : jsonEncode(_contentController.document.toJson());

    await ref.read(learningMaterialProvider.notifier).updateMaterial(
      materialId: widget.material.id,
      title: newTitle,
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      contentText: contentJson,
    );

    if (!mounted) return;

    final state = ref.read(learningMaterialProvider);
    final errMsg = AppErrorMapper.toUserMessage(state.error);
    if (errMsg != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errMsg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      title: 'Edit Module',
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: StyledTextFieldDecoration.styled(
                labelText: 'Title',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: StyledTextFieldDecoration.styled(
                labelText: 'Description (Optional)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            RichTextField(
              controller: _contentController,
              label: 'Content (Optional)',
              icon: Icons.description_outlined,
              minHeight: 150,
            ),
          ],
        ),
      ),
      actions: [
        StyledDialogAction(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        StyledDialogAction(
          label: 'Save Changes',
          isPrimary: true,
          onPressed: _handleSave,
        ),
      ],
    );
  }
}
