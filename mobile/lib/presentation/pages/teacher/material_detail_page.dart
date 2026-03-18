import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/base_card.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/markdown_display.dart';
import 'package:likha/presentation/pages/shared/widgets/primitives/card_icon_slot.dart';
import 'package:likha/presentation/pages/shared/widgets/primitives/status_badge.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/form_message.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/rich_text_field.dart';
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

  void _editMaterial(dynamic material) {
    final titleController = TextEditingController(text: material.title);
    final descController = TextEditingController(text: material.description ?? '');
    late final FleatherController contentController;

    // Initialize content controller with existing content
    if (material.contentText != null && material.contentText!.isNotEmpty) {
      try {
        final doc = ParchmentDocument.fromJson(jsonDecode(material.contentText));
        contentController = FleatherController(document: doc);
      } catch (e) {
        contentController = FleatherController();
      }
    } else {
      contentController = FleatherController();
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFAFAFA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Module'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                RichTextField(
                  controller: contentController,
                  label: 'Content (Optional)',
                  icon: Icons.description_outlined,
                  minHeight: 150,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newTitle = titleController.text.trim();
              if (newTitle.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Title is required')),
                );
                return;
              }

              Navigator.pop(ctx);

              final contentPlainText = contentController.document.toPlainText().trim();
              final contentJson = contentPlainText.isEmpty
                  ? null
                  : jsonEncode(contentController.document.toJson());

              await ref.read(learningMaterialProvider.notifier).updateMaterial(
                    materialId: material.id,
                    title: newTitle,
                    description: descController.text.trim().isEmpty ? null : descController.text.trim(),
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
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2B2B2B),
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
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
              leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF5350)),
              title: const Text('Delete Module', style: TextStyle(color: Color(0xFFEF5350))),
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: state.isLoading && material == null
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF2B2B2B), strokeWidth: 2.5),
              )
            : state.error != null && material == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 64, color: Color(0xFFCCCCCC)),
                        const SizedBox(height: 16),
                        const Text('Failed to load module', style: TextStyle(fontSize: 16, color: Color(0xFF666666))),
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
                                  color: const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.more_vert_rounded,
                                    color: Color(0xFF404040),
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
              color: Color(0xFF2B2B2B),
              letterSpacing: -0.5,
            ),
          ),
          if (material.description != null && material.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(height: 1, color: const Color(0xFFF0F0F0)),
            const SizedBox(height: 12),
            Text(
              material.description!,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF2B2B2B),
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _InfoChip(
                icon: Icons.attach_file_rounded,
                label: '${material.files.length} file(s)',
              ),
              const SizedBox(width: 14),
              _InfoChip(
                icon: Icons.schedule_rounded,
                label: 'Updated ${_formatDate(material.updatedAt)}',
              ),
            ],
          ),
          if (material.needsSync) ...[
            const SizedBox(height: 12),
            const StatusBadge(
              label: 'Pending sync',
              color: Color(0xFF999999),
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
              color: Color(0xFF666666),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          const SizedBox(height: 12),
          MarkdownDisplay(content: material.contentText),
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
                  color: Color(0xFF202020),
                  letterSpacing: -0.4,
                ),
              ),
              FilledButton(
                onPressed: isLoading ? null : _uploadFile,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2B2B2B),
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
          Container(height: 1, color: const Color(0xFFF0F0F0)),
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
                  color: Color(0xFF2B2B2B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                _formatFileSize(file.fileSize),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: file.isCached
                        ? const Icon(Icons.folder_open_rounded)
                        : const Icon(Icons.download_rounded, color: Color(0xFF2B2B2B)),
                    onPressed: isLoading
                        ? null
                        : () => file.isCached
                            ? _openFile(file)
                            : _saveFile(file),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF5350)),
                    onPressed: isLoading ? null : () => _deleteFile(file),
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF666666)),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF666666),
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
