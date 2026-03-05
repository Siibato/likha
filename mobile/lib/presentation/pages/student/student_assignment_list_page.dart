import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/sync/sync_manager.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/pages/student/assignment_detail_page.dart';
import 'package:likha/presentation/pages/student/widgets/assignment_card.dart';
import 'package:likha/presentation/pages/student/widgets/empty_assignment_state.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';
import 'package:likha/presentation/providers/sync_provider.dart';

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
      ref.read(assignmentProvider.notifier).loadAssignments(widget.classId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assignmentProvider);

    // Listen for sync completion to auto-refresh if data arrives after page opens
    ref.listen<SyncState>(syncProvider, (previous, next) {
      if (!(previous?.assignmentsReady ?? false) && next.assignmentsReady) {
        // Assignments just became ready in the DB — reload
        ref.read(assignmentProvider.notifier).loadAssignments(widget.classId);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
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
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2B2B2B),
                        strokeWidth: 2.5,
                      ),
                    )
                  : state.assignments.isEmpty
                      ? const EmptyAssignmentState()
                      : RefreshIndicator(
                          onRefresh: () => ref
                              .read(assignmentProvider.notifier)
                              .loadAssignments(widget.classId),
                          color: const Color(0xFF2B2B2B),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(24),
                            itemCount: state.assignments.length,
                            itemBuilder: (context, index) {
                              final assignment = state.assignments[index];
                              final isPastDue =
                                  DateTime.now().isAfter(assignment.dueAt);

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
                                    submissionType: assignment.submissionType,
                                    totalPoints: assignment.totalPoints,
                                    allowedFileTypes: assignment.allowedFileTypes,
                                    maxFileSizeMb: assignment.maxFileSizeMb,
                                    submissionId: assignment.submissionId,
                                    score: assignment.score,
                                    submissionStatus: assignment.submissionStatus,
                                  ),
                                ),
                              ).then((_) => ref
                                  .read(assignmentProvider.notifier)
                                  .loadAssignments(widget.classId)),
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
