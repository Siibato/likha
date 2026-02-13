import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/providers/learning_material_provider.dart';
import 'package:likha/presentation/pages/teacher/material_detail_page.dart';

class CreateMaterialPage extends ConsumerStatefulWidget {
  final String classId;

  const CreateMaterialPage({super.key, required this.classId});

  @override
  ConsumerState<CreateMaterialPage> createState() => _CreateMaterialPageState();
}

class _CreateMaterialPageState extends ConsumerState<CreateMaterialPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<PlatformFile> _selectedFiles = [];
  final _allowedExtensions = ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'mp4', 'mp3', 'jpg', 'png', 'gif'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one file'),
          backgroundColor: Color(0xFFEF5350),
        ),
      );
      return;
    }

    // Step 1: Create material
    await ref.read(learningMaterialProvider.notifier).createMaterial(
          classId: widget.classId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          contentText: null,
        );

    final state = ref.read(learningMaterialProvider);
    if (state.error != null) {
      return;
    }

    final material = state.currentMaterial;
    if (material == null) {
      return;
    }

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
          if (mounted) {
            ref.read(learningMaterialProvider.notifier).clearMessages();
          }
        }
      }
    }

    if (!mounted) return;

    // Handle results
    if (anyUploadFailed) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Upload Partially Complete'),
          content: const Text(
            'The module was created, but some files failed to upload. '
            'You can retry uploading files in the module detail page.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MaterialDetailPage(materialId: material.id),
                  ),
                );
              },
              child: const Text('Go to Module'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context, true);
              },
              child: const Text('Back'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(learningMaterialProvider);

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
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2B2B2B)),
        title: const Text(
          'Create Module',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B2B),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'e.g., Week 1: Introduction',
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
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Brief description',
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
              validator: (value) {
                if (value != null && value.trim().length > 500) {
                  return 'Description must be at most 500 characters';
                }
                return null;
              },
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
                    color: Color(0xFF2B2B2B),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: state.isLoading ? null : _pickFiles,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2B2B2B)),
                    foregroundColor: const Color(0xFF2B2B2B),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: const Center(
                      child: Text(
                        'No files selected',
                        style: TextStyle(
                          color: Color(0xFF999999),
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
                          side: const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.insert_drive_file_rounded,
                            color: Color(0xFF2B2B2B),
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
                              color: Color(0xFF999999),
                              fontSize: 12,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFFEF5350),
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
            ElevatedButton(
              onPressed: state.isLoading ? null : _createMaterial,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2B2B2B),
                foregroundColor: Colors.white,
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
