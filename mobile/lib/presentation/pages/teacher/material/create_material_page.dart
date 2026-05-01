import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/presentation/providers/learning_material_provider.dart';
import 'package:likha/presentation/pages/teacher/material/material_detail_page.dart';
import 'package:likha/presentation/widgets/shared/dialogs/app_dialogs.dart';
import 'package:likha/presentation/widgets/shared/forms/form_message.dart';
import 'package:likha/presentation/widgets/shared/forms/rich_text_field.dart';

class CreateMaterialPage extends ConsumerStatefulWidget {
  final String classId;

  const CreateMaterialPage({super.key, required this.classId});

  @override
  ConsumerState<CreateMaterialPage> createState() => _CreateMaterialPageState();
}

class _CreateMaterialPageState extends ConsumerState<CreateMaterialPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  late final FleatherController _contentTextController;
  final List<PlatformFile> _selectedFiles = [];
  final _allowedExtensions = ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'mp4', 'mp3', 'jpg', 'png', 'gif'];
  String? _formError;

  @override
  void initState() {
    super.initState();
    _contentTextController = FleatherController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentTextController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
    );
    if (result != null) {
      setState(() => _selectedFiles.addAll(result.files));
    }
  }

  void _removeFile(int index) {
    setState(() => _selectedFiles.removeAt(index));
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _createMaterial() async {
    if (!_formKey.currentState!.validate()) return;

    // Step 1: Create material
    final contentPlainText = _contentTextController.document.toPlainText().trim();

    // Validate: must have either text content or files
    if (contentPlainText.isEmpty && _selectedFiles.isEmpty) {
      setState(() => _formError = 'Add either text content or files');
      return;
    }
    await ref.read(learningMaterialProvider.notifier).createMaterial(
          classId: widget.classId,
          title: _titleController.text.trim(),
          description: null,
          contentText: contentPlainText.isEmpty
              ? null
              : jsonEncode(_contentTextController.document.toJson()),
        );

    final state = ref.read(learningMaterialProvider);
    if (state.error != null) {
      setState(() => _formError = AppErrorMapper.toUserMessage(state.error));
      ref.read(learningMaterialProvider.notifier).clearMessages();
      return;
    }

    final material = state.currentMaterial;
    if (material == null) {
      return;
    }

    if (!mounted) return;

    // Step 2: Upload files sequentially
    bool anyUploadFailed = false;
    for (int i = 0; i < _selectedFiles.length; i++) {
      final file = _selectedFiles[i];
      if (file.path != null) {
        await ref.read(learningMaterialProvider.notifier).uploadFile(
              materialId: material.id,
              filePath: file.path!,
              fileName: file.name,
            );

        final uploadState = ref.read(learningMaterialProvider);
        if (uploadState.error != null) {
          anyUploadFailed = true;
        }
      }
    }

    if (!mounted) return;

    // Handle results - navigate back after brief delay to show message
    if (anyUploadFailed) {
      await Future.delayed(const Duration(milliseconds: 100));
      AppDialogs.showConfirmation(
        context: context,
        title: 'Upload Partially Complete',
        body: 'The module was created, but some files failed to upload. You can try uploading them again from the module page.',
        confirmLabel: 'Go to Module',
        cancelLabel: 'Back',
        onConfirm: () => Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => MaterialDetailPage(materialId: material.id))),
      );
    } else {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(learningMaterialProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSecondary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.accentCharcoal),
        title: const Text(
          'Create Module',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.accentCharcoal,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            FormMessage(
              message: _formError,
              severity: MessageSeverity.error,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'e.g., Week 1: Introduction',
                filled: true,
                fillColor: AppColors.backgroundPrimary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                if (value.trim().length > 200) {
                  return 'Title must be at most 200 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            RichTextField(
              controller: _contentTextController,
              label: 'Content (Optional)',
              icon: Icons.description_outlined,
              minHeight: 200,
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Upload Files',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentCharcoal,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: state.isLoading ? null : _pickFiles,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.accentCharcoal),
                    foregroundColor: AppColors.accentCharcoal,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Select Files',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_selectedFiles.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundPrimary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: const Center(
                      child: Text(
                        'No files selected',
                        style: TextStyle(
                          color: AppColors.foregroundTertiary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else
                  ...List.generate(
                    _selectedFiles.length,
                    (index) {
                      final file = _selectedFiles[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.borderLight),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.insert_drive_file_rounded,
                            color: AppColors.accentCharcoal,
                          ),
                          title: Text(
                            file.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            _formatFileSize(file.size),
                            style: const TextStyle(
                              color: AppColors.foregroundTertiary,
                              fontSize: 12,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.semanticError,
                            ),
                            onPressed: () => _removeFile(index),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Upload progress indicator
            if (state.isLoading && state.currentUploadFileName != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundPrimary,
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
              ),
              const SizedBox(height: 16),
            ],

            ElevatedButton(
              onPressed: state.isLoading ? null : _createMaterial,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentCharcoal,
                foregroundColor: AppColors.backgroundPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: state.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Create Module',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
