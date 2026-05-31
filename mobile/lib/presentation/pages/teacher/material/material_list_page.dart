import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/layouts/mobile/mobile_page_scaffold.dart';
import 'package:likha/core/sync/sync_manager.dart';
import 'package:likha/domain/learning_materials/entities/learning_material.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/pages/teacher/material/create_material_page.dart';
import 'package:likha/presentation/pages/teacher/material/material_detail_page.dart';
import 'package:likha/presentation/widgets/mobile/teacher/dashboard/reorder_position_dialog.dart';
import 'package:likha/presentation/providers/learning_material_provider.dart';
import 'package:likha/presentation/providers/sync_provider.dart';
import 'package:likha/presentation/widgets/shared/layout/refreshable_list.dart';

class TeacherMaterialListPage extends ConsumerStatefulWidget {
  final String classId;

  const TeacherMaterialListPage({super.key, required this.classId});

  @override
  ConsumerState<TeacherMaterialListPage> createState() =>
      _TeacherMaterialListPageState();
}

class _TeacherMaterialListPageState extends ConsumerState<TeacherMaterialListPage>
    with TickerProviderStateMixin {
  bool _isReorderMode = false;
  List<LearningMaterial> _reorderBuffer = [];
  late AnimationController _animController;
  final Map<String, int> _animatingIndices = {};

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(learningMaterialProvider.notifier).loadMaterials(widget.classId);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _enterReorderMode(List<LearningMaterial> materials) {
    setState(() {
      _isReorderMode = true;
      _reorderBuffer = List.of(materials);
    });
  }

  void _exitReorderMode() {
    final notifier = ref.read(learningMaterialProvider.notifier);
    notifier.reorderAllMaterials(
      classId: widget.classId,
      materialIds: _reorderBuffer.map((m) => m.id).toList(),
      orderedMaterials: _reorderBuffer,
    );
    setState(() => _isReorderMode = false);
  }

  void _showMoveToPositionDialog(int currentIndex) {
    showDialog(
      context: context,
      builder: (ctx) => ReorderPositionDialog(
        resourceType: 'materials',
        totalCount: _reorderBuffer.length,
        currentPosition: currentIndex,
        onReorder: _animateReorder,
      ),
    );
  }

  void _animateReorder(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return;

    // Capture old indices for ALL materials before reordering
    _animatingIndices.clear();
    for (int i = 0; i < _reorderBuffer.length; i++) {
      _animatingIndices[_reorderBuffer[i].id] = i;
    }

    // Update the list
    setState(() {
      final material = _reorderBuffer.removeAt(fromIndex);
      _reorderBuffer.insert(toIndex, material);
    });

    // Run the animation
    _animController.forward(from: 0.0).then((_) {
      setState(() {
        _animatingIndices.clear();
      });
    });
  }

  Widget _buildMaterialCard(LearningMaterial material, int index, {bool isAnimated = false, double animOffset = 0}) {
    final card = GestureDetector(
      onTap: _isReorderMode ? () => _showMoveToPositionDialog(index) : () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MaterialDetailPage(materialId: material.id),
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
              if (_isReorderMode)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.accentCharcoal,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: AppColors.accentCharcoal,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              else
                Icon(
                  material.fileCount > 0 ? Icons.attach_file_rounded : Icons.article_outlined,
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

    if (isAnimated) {
      return Transform.translate(
        key: ValueKey(material.id),
        offset: Offset(0, animOffset),
        child: card,
      );
    }
    return card;
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

    return MobilePageScaffold(
      title: 'Learning Modules',
      scrollable: false,
      isLoading: materialState.isLoading && materialState.materials.isEmpty,
      header: const ClassSectionHeader(
        title: 'Learning Modules',
        showBackButton: true,
      ),
      body: Column(
        children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_isReorderMode) ...[
                    TextButton(
                      onPressed: () => setState(() { _isReorderMode = false; }),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _exitReorderMode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentCharcoal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ] else ...[
                    OutlinedButton.icon(
                      onPressed: () => _enterReorderMode(materialState.materials),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentCharcoal,
                        side: const BorderSide(color: AppColors.accentCharcoal),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.reorder_rounded, size: 18),
                      label: const Text('Reorder', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                    const SizedBox(width: 8),
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
                        backgroundColor: AppColors.accentCharcoal,
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
                ],
              ),
            ),
            Expanded(
              child: materialState.materials.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.library_books_outlined, size: 64, color: AppColors.foregroundLight),
                              SizedBox(height: 16),
                              Text('No modules yet', style: TextStyle(fontSize: 16, color: AppColors.foregroundTertiary)),
                            ],
                          ),
                        )
                      : _isReorderMode
                          ? AnimatedBuilder(
                              animation: _animController,
                              builder: (context, _) {
                                return ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                                  itemCount: _reorderBuffer.length,
                                  itemBuilder: (context, index) {
                                    final material = _reorderBuffer[index];
                                    final oldIndex = _animatingIndices[material.id];

                                    // Calculate animation offset based on old position
                                    double animOffset = 0;
                                    if (oldIndex != null && oldIndex != index) {
                                      const cardHeight = 92.0;
                                      animOffset = (oldIndex - index) * cardHeight;
                                    }

                                    // Interpolate from old position to current position
                                    final tween = Tween<double>(begin: animOffset, end: 0);
                                    final currentOffset = tween.evaluate(_animController);

                                    return _buildMaterialCard(
                                      material,
                                      index,
                                      isAnimated: true,
                                      animOffset: currentOffset,
                                    );
                                  },
                                );
                              },
                            )
                          : RefreshableList(
                              onRefresh: () => ref.read(learningMaterialProvider.notifier).loadMaterials(widget.classId),
                              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                              itemCount: materialState.materials.length,
                              itemBuilder: (context, index) {
                                final material = materialState.materials[index];
                                return _buildMaterialCard(material, index);
                              },
                            ),
            ),
          ],
      ),
    );
  }
}
