import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/sync/sync_manager.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/pages/teacher/create_material_page.dart';
import 'package:likha/presentation/pages/teacher/material_detail_page.dart';
import 'package:likha/presentation/providers/learning_material_provider.dart';
import 'package:likha/presentation/providers/sync_provider.dart';

class TeacherMaterialListPage extends ConsumerStatefulWidget {
  final String classId;

  const TeacherMaterialListPage({super.key, required this.classId});

  @override
  ConsumerState<TeacherMaterialListPage> createState() =>
      _TeacherMaterialListPageState();
}

class _TeacherMaterialListPageState extends ConsumerState<TeacherMaterialListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(learningMaterialProvider.notifier).loadMaterials(widget.classId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final materialState = ref.watch(learningMaterialProvider);

    // Listen for sync completion to auto-refresh if data arrives after page opens
    ref.listen<SyncState>(syncProvider, (previous, next) {
      if (!(previous?.materialsReady ?? false) && next.materialsReady) {
        // Materials just became ready in the DB — reload
        ref.read(learningMaterialProvider.notifier).loadMaterials(widget.classId);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: null,
      body: SafeArea(
        child: Column(
          children: [
            ClassSectionHeader(
              title: 'Learning Modules',
              showBackButton: true,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateMaterialPage(classId: widget.classId),
                      ),
                    ).then((result) {
                      if (result == true) {
                        ref.read(learningMaterialProvider.notifier).loadMaterials(widget.classId);
                      }
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B2B2B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(
                      'Create',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: materialState.isLoading && materialState.materials.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2B2B2B),
                        strokeWidth: 2.5,
                      ),
                    )
                  : materialState.materials.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.library_books_outlined, size: 64, color: Color(0xFFCCCCCC)),
                              SizedBox(height: 16),
                              Text('No modules yet', style: TextStyle(fontSize: 16, color: Color(0xFF999999))),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => ref.read(learningMaterialProvider.notifier).loadMaterials(widget.classId),
                          color: const Color(0xFF2B2B2B),
                          child: ReorderableListView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                            itemCount: materialState.materials.length,
                            onReorder: (oldIndex, newIndex) {
                              final material = materialState.materials[oldIndex];
                              ref.read(learningMaterialProvider.notifier).reorderMaterial(
                                    material.id,
                                    newIndex > oldIndex ? newIndex - 1 : newIndex,
                                  );
                            },
                            itemBuilder: (context, index) {
                              final material = materialState.materials[index];
                              return Card(
                                key: ValueKey(material.id),
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: Color(0xFFE0E0E0)),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: Icon(
                                    material.fileCount > 0 ? Icons.attach_file_rounded : Icons.article_outlined,
                                    color: const Color(0xFF2B2B2B),
                                  ),
                                  title: Text(
                                    material.title,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: material.description != null
                                      ? Text(material.description!, maxLines: 2, overflow: TextOverflow.ellipsis)
                                      : null,
                                  trailing: Text(
                                    '${material.fileCount} file(s)',
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
                                  ),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MaterialDetailPage(materialId: material.id),
                                    ),
                                  ).then((_) {
                                    // Reload materials when returning from detail page
                                    // to pick up any file count changes
                                    ref.read(learningMaterialProvider.notifier).loadMaterials(widget.classId);
                                  }),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
