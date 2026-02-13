import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/providers/learning_material_provider.dart';
import 'package:path_provider/path_provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  Future<void> _downloadFile(String fileId, String fileName) async {
    final bytes = await ref.read(learningMaterialProvider.notifier).downloadFile(fileId);
    if (bytes == null || !mounted) return;

    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/$fileName';
    final fileObj = File(filePath);
    await fileObj.writeAsBytes(bytes);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('File saved to: $filePath'),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 4),
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
                    ...material.files.map((file) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.insert_drive_file_rounded, color: Color(0xFF2B2B2B)),
                            title: Text(file.fileName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${(file.fileSize / 1024 / 1024).toStringAsFixed(2)} MB'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.download_rounded),
                                  onPressed: () => _downloadFile(file.id, file.fileName),
                                  color: const Color(0xFF2B2B2B),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded),
                                  onPressed: () => _deleteFile(file.id),
                                  color: const Color(0xFFEF5350),
                                ),
                              ],
                            ),
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}
