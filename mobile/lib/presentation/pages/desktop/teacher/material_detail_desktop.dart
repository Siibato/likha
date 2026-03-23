import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/learning_materials/entities/material_file.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/shared/widgets/dialogs/app_dialogs.dart';
import 'package:likha/presentation/providers/learning_material_provider.dart';
import 'package:likha/presentation/utils/formatters.dart';

class MaterialDetailDesktop extends ConsumerStatefulWidget {
  final String materialId;

  const MaterialDetailDesktop({super.key, required this.materialId});

  @override
  ConsumerState<MaterialDetailDesktop> createState() =>
      _MaterialDetailDesktopState();
}

class _MaterialDetailDesktopState
    extends ConsumerState<MaterialDetailDesktop> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(learningMaterialProvider.notifier)
          .loadMaterialDetail(widget.materialId);
    });
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _uploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: [
        'pdf', 'doc', 'docx', 'ppt', 'pptx',
        'mp4', 'mp3', 'jpg', 'png', 'gif',
      ],
    );

    if (result != null && result.files.single.path != null) {
      await ref.read(learningMaterialProvider.notifier).uploadFile(
            materialId: widget.materialId,
            filePath: result.files.single.path!,
            fileName: result.files.single.name,
          );
    }
  }

  Future<void> _downloadFile(MaterialFile file) async {
    await ref.read(learningMaterialProvider.notifier).downloadFile(file.id);
  }

  void _deleteFile(MaterialFile file) {
    AppDialogs.showDestructive(
      context: context,
      title: 'Delete File',
      body: 'Are you sure you want to delete "${file.fileName}"?',
      confirmLabel: 'Delete',
      onConfirm: () => ref
          .read(learningMaterialProvider.notifier)
          .deleteFile(file.id, widget.materialId),
    );
  }

  void _showEditDialog() {
    final material = ref.read(learningMaterialProvider).currentMaterial;
    if (material == null) return;

    final titleController = TextEditingController(text: material.title);
    final contentController =
        TextEditingController(text: material.contentText ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundSecondary,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Module'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 500,
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
                      borderSide:
                          const BorderSide(color: AppColors.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.borderLight),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: contentController,
                  decoration: InputDecoration(
                    labelText: 'Content (Optional)',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.borderLight),
                    ),
                  ),
                  maxLines: 8,
                  minLines: 4,
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

              final content = contentController.text.trim();
              await ref
                  .read(learningMaterialProvider.notifier)
                  .updateMaterial(
                    materialId: material.id,
                    title: newTitle,
                    description: null,
                    contentText: content.isEmpty ? null : content,
                  );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.foregroundPrimary,
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMaterial() {
    final title = ref.read(learningMaterialProvider).currentMaterial?.title ??
        'this module';
    AppDialogs.showDestructive(
      context: context,
      title: 'Delete Module',
      body:
          'Are you sure you want to permanently delete "$title" and all of its contents? This cannot be undone.',
      confirmLabel: 'Delete',
      onConfirm: () => ref
          .read(learningMaterialProvider.notifier)
          .deleteMaterial(widget.materialId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(learningMaterialProvider);
    final material = state.currentMaterial;

    ref.listen<LearningMaterialState>(learningMaterialProvider, (prev, next) {
      // Handle delete success
      if (next.successMessage == 'Material deleted successfully') {
        ref.read(learningMaterialProvider.notifier).clearMessages();
        if (mounted) Navigator.pop(context, true);
        return;
      }

      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppErrorMapper.toUserMessage(next.error) ?? 'An error occurred'),
            backgroundColor: AppColors.semanticError,
          ),
        );
        ref.read(learningMaterialProvider.notifier).clearMessages();
      }

      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.semanticSuccess,
          ),
        );
        ref.read(learningMaterialProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: material?.title ?? 'Module Detail',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        actions: [
          if (material != null) ...[
            OutlinedButton.icon(
              onPressed: state.isLoading ? null : _uploadFile,
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: const Text('Upload File'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.foregroundDark,
                side: const BorderSide(color: AppColors.borderLight),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppColors.foregroundDark),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showEditDialog();
                    break;
                  case 'delete':
                    _confirmDeleteMaterial();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded,
                          size: 18, color: AppColors.foregroundSecondary),
                      SizedBox(width: 12),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_rounded,
                          size: 18, color: AppColors.semanticError),
                      SizedBox(width: 12),
                      Text('Delete',
                          style: TextStyle(color: AppColors.semanticError)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
        body: state.isLoading && material == null
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.foregroundPrimary,
                  strokeWidth: 2.5,
                ),
              )
            : material == null
                ? const Center(
                    child: Text(
                      'Module not found',
                      style: TextStyle(color: AppColors.foregroundTertiary),
                    ),
                  )
                : SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left column: content display
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Description
                              if (material.description != null &&
                                  material.description!.isNotEmpty) ...[
                                _buildContentSection(
                                  'Description',
                                  material.description!,
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Content text
                              if (material.contentText != null &&
                                  material.contentText!.isNotEmpty) ...[
                                _buildContentTextSection(
                                    material.contentText!),
                                const SizedBox(height: 24),
                              ],

                              // Info chips
                              _buildInfoChips(material),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Right column: files panel
                        Expanded(
                          flex: 1,
                          child: _buildFilesPanel(material, state.isLoading),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildContentSection(String heading, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundDark,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderLight),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.foregroundSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentTextSection(String contentText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Content',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundDark,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderLight),
          const SizedBox(height: 12),
          SelectableText(
            contentText,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.foregroundSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChips(dynamic material) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _buildChip(
          Icons.attach_file_rounded,
          '${material.files.length} file(s)',
        ),
        _buildChip(
          Icons.schedule_rounded,
          'Updated ${_formatDate(material.updatedAt)}',
        ),
      ],
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.foregroundTertiary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.foregroundSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesPanel(dynamic material, bool isLoading) {
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
                            formatFileSize(file.fileSize),
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
                        file.isCached
                            ? Icons.folder_open_rounded
                            : Icons.download_rounded,
                        size: 18,
                        color: AppColors.foregroundPrimary,
                      ),
                      onPressed:
                          isLoading ? null : () => _downloadFile(file),
                      tooltip: file.isCached ? 'Open' : 'Download',
                      splashRadius: 18,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: AppColors.semanticError,
                      ),
                      onPressed:
                          isLoading ? null : () => _deleteFile(file),
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
              onPressed: isLoading ? null : _uploadFile,
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: const Text('Upload File'),
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
