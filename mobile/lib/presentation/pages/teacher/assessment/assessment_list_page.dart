import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/sync/sync_manager.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/pages/teacher/assessment/assessment_detail_page.dart';
import 'package:likha/presentation/pages/teacher/assessment/create_assessment_page.dart';
import 'package:likha/presentation/pages/teacher/assessment/widgets/empty_assessment_list_state.dart';
import 'package:likha/presentation/pages/teacher/widgets/reorder_position_dialog.dart';
import 'package:likha/presentation/pages/teacher/assessment/widgets/teacher_assessment_card.dart';
import 'package:likha/presentation/providers/teacher_assessment_provider.dart';
import 'package:likha/presentation/providers/sync_provider.dart';

class TeacherAssessmentListPage extends ConsumerStatefulWidget {
  final String classId;

  const TeacherAssessmentListPage({super.key, required this.classId});

  @override
  ConsumerState<TeacherAssessmentListPage> createState() =>
      _TeacherAssessmentListPageState();
}

class _TeacherAssessmentListPageState extends ConsumerState<TeacherAssessmentListPage>
    with TickerProviderStateMixin {
  bool _isReorderMode = false;
  List<Assessment> _reorderBuffer = [];
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
      ref.read(teacherAssessmentProvider.notifier).loadAssessments(widget.classId);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _enterReorderMode(List<Assessment> assessments) {
    setState(() {
      _isReorderMode = true;
      _reorderBuffer = List.of(assessments);
    });
  }

  void _exitReorderMode() {
    final notifier = ref.read(teacherAssessmentProvider.notifier);
    notifier.reorderAllAssessments(
      classId: widget.classId,
      assessmentIds: _reorderBuffer.map((a) => a.id).toList(),
      orderedAssessments: _reorderBuffer,
    );
    setState(() => _isReorderMode = false);
  }

  void _showMoveToPositionDialog(int currentIndex) {
    showDialog(
      context: context,
      builder: (ctx) => ReorderPositionDialog(
        resourceType: 'assessments',
        totalCount: _reorderBuffer.length,
        currentPosition: currentIndex,
        onReorder: _animateReorder,
      ),
    );
  }

  void _animateReorder(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return;

    // Capture old indices for ALL assessments before reordering
    _animatingIndices.clear();
    for (int i = 0; i < _reorderBuffer.length; i++) {
      _animatingIndices[_reorderBuffer[i].id] = i;
    }

    // Update the list
    setState(() {
      final assessment = _reorderBuffer.removeAt(fromIndex);
      _reorderBuffer.insert(toIndex, assessment);
    });

    // Run the animation
    _animController.forward(from: 0.0).then((_) {
      setState(() {
        _animatingIndices.clear();
      });
    });
  }

  Widget _buildAssessmentCard(Assessment assessment, int index, {bool isAnimated = false, double animOffset = 0}) {
    final card = GestureDetector(
      onTap: _isReorderMode ? () => _showMoveToPositionDialog(index) : () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AssessmentDetailPage(assessmentId: assessment.id),
        ),
      ).then((_) {
        ref.read(teacherAssessmentProvider.notifier).loadAssessments(widget.classId);
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.accentCharcoal,
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
                const Icon(
                  Icons.quiz_outlined,
                  color: AppColors.accentCharcoal,
                  size: 20,
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assessment.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.foregroundDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${assessment.questionCount} question(s)',
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
        key: ValueKey(assessment.id),
        offset: Offset(0, animOffset),
        child: card,
      );
    }
    return card;
  }

  @override
  Widget build(BuildContext context) {
    final assessmentState = ref.watch(teacherAssessmentProvider);

    // Listen for sync completion to auto-refresh if data arrives after page opens
    ref.listen<SyncState>(syncProvider, (previous, next) {
      if (!(previous?.assessmentsReady ?? false) && next.assessmentsReady) {
        // Assessments just became ready in the DB — reload
        ref.read(teacherAssessmentProvider.notifier).loadAssessments(widget.classId, skipBackgroundRefresh: true);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: null,
      body: SafeArea(
        child: Column(
          children: [
            const ClassSectionHeader(
              title: 'Assessments',
              showBackButton: true,
            ),
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
                      onPressed: () => _enterReorderMode(assessmentState.assessments),
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
                          builder: (_) => CreateAssessmentPage(classId: widget.classId),
                        ),
                      ).then((result) {
                        if (result == true) {
                          ref.read(teacherAssessmentProvider.notifier).loadAssessments(widget.classId);
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
              child: assessmentState.isLoading && assessmentState.assessments.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentCharcoal,
                        strokeWidth: 2.5,
                      ),
                    )
                  : assessmentState.assessments.isEmpty
                      ? const EmptyAssessmentListState()
                      : _isReorderMode
                          ? AnimatedBuilder(
                              animation: _animController,
                              builder: (context, _) {
                                return ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                                  itemCount: _reorderBuffer.length,
                                  itemBuilder: (context, index) {
                                    final assessment = _reorderBuffer[index];
                                    final oldIndex = _animatingIndices[assessment.id];

                                    // Calculate animation offset based on old position
                                    double animOffset = 0;
                                    if (oldIndex != null && oldIndex != index) {
                                      const cardHeight = 92.0;
                                      animOffset = (oldIndex - index) * cardHeight;
                                    }

                                    // Interpolate from old position to current position
                                    final tween = Tween<double>(begin: animOffset, end: 0);
                                    final currentOffset = tween.evaluate(_animController);

                                    return _buildAssessmentCard(
                                      assessment,
                                      index,
                                      isAnimated: true,
                                      animOffset: currentOffset,
                                    );
                                  },
                                );
                              },
                            )
                          : RefreshIndicator(
                              onRefresh: () => ref
                                  .read(teacherAssessmentProvider.notifier)
                                  .loadAssessments(widget.classId),
                              color: AppColors.accentCharcoal,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                                itemCount: assessmentState.assessments.length,
                                itemBuilder: (context, index) {
                                  final assessment = assessmentState.assessments[index];
                                  return TeacherAssessmentCard(
                                    assessment: assessment,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AssessmentDetailPage(
                                          assessmentId: assessment.id,
                                        ),
                                      ),
                                    ).then((_) => ref
                                        .read(teacherAssessmentProvider.notifier)
                                        .loadAssessments(widget.classId)),
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
