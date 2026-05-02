import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/layouts/mobile/mobile_page_scaffold.dart';
import 'package:likha/core/sync/sync_manager.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/pages/teacher/assignment/assignment_detail_page.dart';
import 'package:likha/presentation/pages/teacher/assignment/create_assignment_page.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assignment/empty_assignment_list_state.dart';
import 'package:likha/presentation/widgets/mobile/teacher/dashboard/reorder_position_dialog.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assignment/teacher_assignment_card.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';
import 'package:likha/presentation/providers/sync_provider.dart';
import 'package:likha/presentation/widgets/shared/layout/refreshable_list.dart';

class TeacherAssignmentListPage extends ConsumerStatefulWidget {
  final String classId;

  const TeacherAssignmentListPage({super.key, required this.classId});

  @override
  ConsumerState<TeacherAssignmentListPage> createState() =>
      _TeacherAssignmentListPageState();
}

class _TeacherAssignmentListPageState extends ConsumerState<TeacherAssignmentListPage>
    with TickerProviderStateMixin {
  bool _isReorderMode = false;
  List<Assignment> _reorderBuffer = [];
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
      ref.read(assignmentProvider.notifier).loadAssignments(widget.classId);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _enterReorderMode(List<Assignment> assignments) {
    setState(() {
      _isReorderMode = true;
      _reorderBuffer = List.of(assignments);
    });
  }

  void _exitReorderMode() {
    final notifier = ref.read(assignmentProvider.notifier);
    notifier.reorderAllAssignments(
      classId: widget.classId,
      assignmentIds: _reorderBuffer.map((a) => a.id).toList(),
      orderedAssignments: _reorderBuffer,
    );
    setState(() => _isReorderMode = false);
  }

  void _showMoveToPositionDialog(int currentIndex) {
    showDialog(
      context: context,
      builder: (ctx) => ReorderPositionDialog(
        resourceType: 'assignments',
        totalCount: _reorderBuffer.length,
        currentPosition: currentIndex,
        onReorder: _animateReorder,
      ),
    );
  }

  void _animateReorder(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return;

    // Capture old indices for ALL assignments before reordering
    _animatingIndices.clear();
    for (int i = 0; i < _reorderBuffer.length; i++) {
      _animatingIndices[_reorderBuffer[i].id] = i;
    }

    // Update the list
    setState(() {
      final assignment = _reorderBuffer.removeAt(fromIndex);
      _reorderBuffer.insert(toIndex, assignment);
    });

    // Run the animation
    _animController.forward(from: 0.0).then((_) {
      setState(() {
        _animatingIndices.clear();
      });
    });
  }

  Widget _buildAssignmentCard(Assignment assignment, int index, {bool isAnimated = false, double animOffset = 0}) {
    final card = GestureDetector(
      onTap: _isReorderMode ? () => _showMoveToPositionDialog(index) : () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AssignmentDetailPage(assignmentId: assignment.id),
        ),
      ).then((_) {
        ref.read(assignmentProvider.notifier).loadAssignments(widget.classId);
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
                const Icon(
                  Icons.assignment_outlined,
                  color: AppColors.accentCharcoal,
                  size: 20,
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.foregroundDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${assignment.submissionCount} submission(s)',
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
        key: ValueKey(assignment.id),
        offset: Offset(0, animOffset),
        child: card,
      );
    }
    return card;
  }

  @override
  Widget build(BuildContext context) {
    final assignmentState = ref.watch(assignmentProvider);

    // Listen for sync completion to auto-refresh if data arrives after page opens
    ref.listen<SyncState>(syncProvider, (previous, next) {
      if (!(previous?.assignmentsReady ?? false) && next.assignmentsReady) {
        // Assignments just became ready in the DB — reload
        ref.read(assignmentProvider.notifier).loadAssignments(widget.classId, skipBackgroundRefresh: true);
      }
    });

    return MobilePageScaffold(
      title: 'Assignments',
      scrollable: false,
      isLoading: assignmentState.isLoading && assignmentState.assignments.isEmpty,
      header: const ClassSectionHeader(
        title: 'Assignments',
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
                      onPressed: () => _enterReorderMode(assignmentState.assignments),
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
                          builder: (_) => CreateAssignmentPage(classId: widget.classId),
                        ),
                      ).then((result) {
                        if (result == true) {
                          ref.read(assignmentProvider.notifier).loadAssignments(widget.classId);
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
              child: assignmentState.assignments.isEmpty
                      ? const EmptyAssignmentListState()
                      : _isReorderMode
                          ? AnimatedBuilder(
                              animation: _animController,
                              builder: (context, _) {
                                return ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                                  itemCount: _reorderBuffer.length,
                                  itemBuilder: (context, index) {
                                    final assignment = _reorderBuffer[index];
                                    final oldIndex = _animatingIndices[assignment.id];

                                    // Calculate animation offset based on old position
                                    double animOffset = 0;
                                    if (oldIndex != null && oldIndex != index) {
                                      const cardHeight = 92.0;
                                      animOffset = (oldIndex - index) * cardHeight;
                                    }

                                    // Interpolate from old position to current position
                                    final tween = Tween<double>(begin: animOffset, end: 0);
                                    final currentOffset = tween.evaluate(_animController);

                                    return _buildAssignmentCard(
                                      assignment,
                                      index,
                                      isAnimated: true,
                                      animOffset: currentOffset,
                                    );
                                  },
                                );
                              },
                            )
                          : RefreshableList(
                              onRefresh: () => ref
                                  .read(assignmentProvider.notifier)
                                  .loadAssignments(widget.classId),
                              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                              itemCount: assignmentState.assignments.length,
                              itemBuilder: (context, index) {
                                final assignment = assignmentState.assignments[index];
                                return TeacherAssignmentCard(
                                  assignment: assignment,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AssignmentDetailPage(
                                        assignmentId: assignment.id,
                                      ),
                                    ),
                                  ).then((_) => ref
                                      .read(assignmentProvider.notifier)
                                      .loadAssignments(widget.classId)),
                                );
                              },
                            ),
            ),
          ],
      ),
    );
  }
}
