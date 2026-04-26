import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/services/server_clock_service.dart';
import 'package:likha/core/sync/sync_manager.dart';
import 'package:likha/injection_container.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/pages/student/assignment/assignment_detail_page.dart';
import 'package:likha/presentation/pages/student/assignment/widgets/assignment_card.dart';
import 'package:likha/presentation/pages/student/assignment/widgets/empty_assignment_state.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';
import 'package:likha/presentation/providers/sync_provider.dart';
import 'package:likha/presentation/pages/shared/widgets/skeletons/skeleton_pulse.dart';
import 'package:likha/presentation/pages/shared/widgets/skeletons/assignment_card_skeleton.dart';

class StudentAssignmentListPage extends ConsumerStatefulWidget {
  final String classId;

  const StudentAssignmentListPage({super.key, required this.classId});

  @override
  ConsumerState<StudentAssignmentListPage> createState() =>
      _StudentAssignmentListPageState();
}

class _StudentAssignmentListPageState extends ConsumerState<StudentAssignmentListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(assignmentProvider.notifier).loadAssignments(widget.classId, publishedOnly: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assignmentProvider);

    // Listen for sync completion to auto-refresh if data arrives after page opens
    ref.listen<SyncState>(syncProvider, (previous, next) {
      if (!(previous?.assignmentsReady ?? false) && next.assignmentsReady) {
        // Assignments just became ready in the DB — reload
        ref.read(assignmentProvider.notifier).loadAssignments(widget.classId, publishedOnly: true, skipBackgroundRefresh: true);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: null,
      body: SafeArea(
        child: Column(
          children: [
            const ClassSectionHeader(
              title: 'Assignments',
              showBackButton: true,
            ),
            Expanded(
              child: state.isLoading && state.assignments.isEmpty
                  ? SkeletonPulse(
                      child: ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        itemCount: 6,
                        itemBuilder: (_, __) => const AssignmentCardSkeleton(),
                      ),
                    )
                  : state.assignments.isEmpty
                      ? const EmptyAssignmentState()
                      : RefreshIndicator(
                          onRefresh: () => ref
                              .read(assignmentProvider.notifier)
                              .loadAssignments(widget.classId, publishedOnly: true),
                          color: AppColors.accentCharcoal,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(24),
                            itemCount: state.assignments.length,
                            itemBuilder: (context, index) {
                              final assignment = state.assignments[index];
                              final isPastDue =
                                  sl<ServerClockService>().now().isAfter(assignment.dueAt);

                            return AssignmentCard(
                              title: assignment.title,
                              totalPoints: assignment.totalPoints,
                              dueAt: assignment.dueAt,
                              isPastDue: isPastDue,
                              submissionStatus: assignment.submissionStatus,
                              score: assignment.score,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AssignmentDetailPage(
                                    assignmentId: assignment.id,
                                    assignmentTitle: assignment.title,
                                    instructions: assignment.instructions,
                                    allowsTextSubmission: assignment.allowsTextSubmission,
                                    allowsFileSubmission: assignment.allowsFileSubmission,
                                    totalPoints: assignment.totalPoints,
                                    allowedFileTypes: assignment.allowedFileTypes,
                                    maxFileSizeMb: assignment.maxFileSizeMb,
                                    submissionId: assignment.submissionId,
                                    score: assignment.score,
                                    submissionStatus: assignment.submissionStatus,
                                    dueAt: assignment.dueAt,
                                  ),
                                ),
                              ).then((_) => ref
                                  .read(assignmentProvider.notifier)
                                  .loadAssignments(widget.classId, publishedOnly: true)),
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
