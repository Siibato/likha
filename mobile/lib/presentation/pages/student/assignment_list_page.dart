import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/presentation/pages/student/submit_assignment_page.dart';
import 'package:likha/presentation/pages/student/assignment_result_page.dart';
import 'package:likha/presentation/pages/student/widgets/student_header.dart';
import 'package:likha/presentation/pages/student/widgets/assignment_list_card.dart';
import 'package:likha/presentation/pages/student/widgets/empty_assignment_state.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';

class AssignmentListPage extends ConsumerStatefulWidget {
  final String classId;

  const AssignmentListPage({super.key, required this.classId});

  @override
  ConsumerState<AssignmentListPage> createState() =>
      _AssignmentListPageState();
}

class _AssignmentListPageState extends ConsumerState<AssignmentListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(assignmentProvider.notifier).loadAssignments(widget.classId);
    });
  }

  AssignmentStatus _getStatus(Assignment assignment) {
    final now = DateTime.now();
    if (assignment.gradedCount > 0) {
      return AssignmentStatus.graded;
    }
    if (assignment.submissionCount > 0) {
      return AssignmentStatus.submitted;
    }
    if (now.isAfter(assignment.dueAt)) {
      return AssignmentStatus.pastDue;
    }
    return AssignmentStatus.open;
  }

  void _onAssignmentTap(Assignment assignment) {
    final status = _getStatus(assignment);
    if (status == AssignmentStatus.graded) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AssignmentResultPage(
            assignmentId: assignment.id,
            assignmentTitle: assignment.title,
            totalPoints: assignment.totalPoints,
          ),
        ),
      ).then((_) => ref
          .read(assignmentProvider.notifier)
          .loadAssignments(widget.classId));
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SubmitAssignmentPage(
            assignmentId: assignment.id,
            assignmentTitle: assignment.title,
            instructions: assignment.instructions,
            submissionType: assignment.submissionType,
            totalPoints: assignment.totalPoints,
            allowedFileTypes: assignment.allowedFileTypes,
            maxFileSizeMb: assignment.maxFileSizeMb,
          ),
        ),
      ).then((_) => ref
          .read(assignmentProvider.notifier)
          .loadAssignments(widget.classId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assignmentProvider);

    ref.listen<AssignmentState>(assignmentProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: const Color(0xFFEA4335),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        ref.read(assignmentProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: state.isLoading && state.assignments.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2B2B2B),
                  strokeWidth: 2.5,
                ),
              )
            : RefreshIndicator(
                onRefresh: () => ref
                    .read(assignmentProvider.notifier)
                    .loadAssignments(widget.classId),
                color: const Color(0xFF2B2B2B),
                child: CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(
                      child: StudentHeader(title: 'Assignments'),
                    ),
                    state.assignments.isEmpty
                        ? const SliverFillRemaining(
                            child: EmptyAssignmentState(),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final assignment = state.assignments[index];
                                  final status = _getStatus(assignment);
                                  return AssignmentListCard(
                                    assignment: assignment,
                                    status: status,
                                    onTap: () => _onAssignmentTap(assignment),
                                  );
                                },
                                childCount: state.assignments.length,
                              ),
                            ),
                          ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 40),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}