import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/sync/sync_manager.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/pages/teacher/material_detail_page.dart';
import 'package:likha/presentation/providers/learning_material_provider.dart';
import 'package:likha/presentation/providers/sync_provider.dart';

class StudentMaterialListPage extends ConsumerStatefulWidget {
  final String classId;

  const StudentMaterialListPage({super.key, required this.classId});

  @override
  ConsumerState<StudentMaterialListPage> createState() =>
      _StudentMaterialListPageState();
}

class _StudentMaterialListPageState extends ConsumerState<StudentMaterialListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(learningMaterialProvider.notifier).loadMaterials(widget.classId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(learningMaterialProvider);

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
            const ClassSectionHeader(
              title: 'Learning Modules',
              showBackButton: true,
            ),
            Expanded(
              child: state.isLoading && state.materials.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2B2B2B),
                        strokeWidth: 2.5,
                      ),
                    )
                  : state.error != null && state.materials.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.wifi_off_rounded,
                                size: 64,
                                color: const Color(0xFFCCCCCC),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Learning modules unavailable',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF666666),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                  'Connect to the internet to view modules',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF999999),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 24),
                              OutlinedButton(
                                onPressed: () => ref
                                    .read(learningMaterialProvider.notifier)
                                    .loadMaterials(widget.classId),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : state.materials.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.library_books_outlined,
                                    size: 64,
                                    color: Color(0xFFCCCCCC),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No modules yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF999999),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                        onRefresh: () => ref
                            .read(learningMaterialProvider.notifier)
                            .loadMaterials(widget.classId),
                        color: const Color(0xFF2B2B2B),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: state.materials.length,
                          itemBuilder: (context, index) {
                            final material = state.materials[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Icon(
                                  material.fileCount > 0
                                      ? Icons.attach_file_rounded
                                      : Icons.article_outlined,
                                  color: const Color(0xFF2B2B2B),
                                ),
                                title: Text(
                                  material.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: material.description != null
                                    ? Text(
                                        material.description!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    : null,
                                trailing: Text(
                                  '${material.fileCount} file(s)',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF999999),
                                  ),
                                ),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MaterialDetailPage(
                                      materialId: material.id,
                                    ),
                                  ),
                                ).then((_) {
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
