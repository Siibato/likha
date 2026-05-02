import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/layouts/mobile/mobile_page_scaffold.dart';
import 'package:likha/core/sync/sync_manager.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/pages/student/material/material_detail_page.dart';
import 'package:likha/presentation/providers/learning_material_provider.dart';
import 'package:likha/presentation/providers/sync_provider.dart';
import 'package:likha/presentation/widgets/shared/skeletons/skeleton_pulse.dart';
import 'package:likha/presentation/widgets/shared/skeletons/material_card_skeleton.dart';
import 'package:likha/presentation/widgets/shared/layout/refreshable_list.dart';

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

    return MobilePageScaffold(
      title: 'Learning Modules',
      scrollable: false,
      header: const ClassSectionHeader(
        title: 'Learning Modules',
        showBackButton: true,
      ),
      body: state.isLoading && state.materials.isEmpty
          ? SkeletonPulse(
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                itemCount: 5,
                itemBuilder: (_, __) => const MaterialCardSkeleton(),
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
                        color: AppColors.foregroundLight,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No modules yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.foregroundTertiary,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshableList(
                  onRefresh: () => ref
                      .read(learningMaterialProvider.notifier)
                      .loadMaterials(widget.classId),
                  padding: const EdgeInsets.all(24),
                  itemCount: state.materials.length,
                  itemBuilder: (context, index) {
                    final material = state.materials[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentMaterialDetailPage(
                            materialId: material.id,
                          ),
                        ),
                      ).then((_) {
                        ref.read(learningMaterialProvider.notifier).loadMaterials(widget.classId);
                      }),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.borderLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(1, 1, 1, 2.5),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                material.fileCount > 0
                                    ? Icons.attach_file_rounded
                                    : Icons.article_outlined,
                                color: AppColors.accentCharcoal,
                                size: 20,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      material.title,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.foregroundDark,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${material.fileCount} file(s)',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.foregroundTertiary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.foregroundLight,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
  }
}
