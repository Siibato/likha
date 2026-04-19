import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/shared/widgets/dialogs/app_dialogs.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/form_message.dart';
import 'package:likha/presentation/providers/learning_material_provider.dart';

class CreateMaterialDesktop extends ConsumerStatefulWidget {
  final String classId;

  const CreateMaterialDesktop({super.key, required this.classId});

  @override
  ConsumerState<CreateMaterialDesktop> createState() =>
      _CreateMaterialDesktopState();
}

class _CreateMaterialDesktopState
    extends ConsumerState<CreateMaterialDesktop> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final List<PlatformFile> _selectedFiles = [];
  String? _formError;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        'pdf', 'doc', 'docx', 'ppt', 'pptx',
        'mp4', 'mp3', 'jpg', 'png', 'gif',
      ],
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

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final content = _contentController.text.trim();

    // Validate: must have either text content or files
    if (content.isEmpty && _selectedFiles.isEmpty) {
      setState(() => _formError = 'Add either text content or files');
      return;
    }

    setState(() => _formError = null);

    // Step 1: Create material
    await ref.read(learningMaterialProvider.notifier).createMaterial(
          classId: widget.classId,
          title: _titleController.text.trim(),
          description: null,
          contentText: content.isEmpty ? null : content,
        );

    final state = ref.read(learningMaterialProvider);
    if (state.error != null) {
      setState(() => _formError = AppErrorMapper.toUserMessage(state.error));
      ref.read(learningMaterialProvider.notifier).clearMessages();
      return;
    }

    final material = state.currentMaterial;
    if (material == null) return;
    if (!mounted) return;

    // Step 2: Upload files sequentially
    bool anyUploadFailed = false;
    for (final file in _selectedFiles) {
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

    if (anyUploadFailed) {
      AppDialogs.showConfirmation(
        context: context,
        title: 'Upload Partially Complete',
        body:
            'The module was created, but some files failed to upload. You can try uploading them again from the module page.',
        confirmLabel: 'OK',
        onConfirm: () {
          if (mounted) Navigator.pop(context, true);
        },
      );
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(learningMaterialProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: 'Create Module',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FormMessage(
                      message: _formError,
                      severity: MessageSeverity.error,
                    ),
                    if (_formError != null) const SizedBox(height: 12),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: _inputDecoration('Title'),
                      maxLength: 200,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Title is required';
                        }
                        if (v.trim().length > 200) {
                          return 'Title must be at most 200 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Content
                    TextFormField(
                      controller: _contentController,
                      decoration: _inputDecoration('Content (Optional)'),
                      maxLines: 8,
                      minLines: 4,
                    ),
                    const SizedBox(height: 24),

                    // File upload section
                    const Text(
                      'Upload Files',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foregroundDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: state.isLoading ? null : _pickFiles,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.borderPrimary),
                        foregroundColor: AppColors.foregroundPrimary,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
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
                          color: AppColors.backgroundSecondary,
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
                      ...List.generate(_selectedFiles.length, (index) {
                        final file = _selectedFiles[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.insert_drive_file_rounded,
                              color: AppColors.foregroundPrimary,
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
                      }),
                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: state.isLoading ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.foregroundPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: state.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Create Module',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontSize: 14,
        color: AppColors.foregroundSecondary,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppColors.foregroundPrimary, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
