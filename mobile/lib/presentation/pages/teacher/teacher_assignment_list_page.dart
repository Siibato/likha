import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/sync/sync_manager.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/pages/teacher/assignment_detail_page.dart';
import 'package:likha/presentation/pages/teacher/create_assignment_page.dart';
import 'package:likha/presentation/pages/teacher/widgets/empty_assignment_list_state.dart';
import 'package:likha/presentation/pages/teacher/widgets/teacher_assignment_card.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';
import 'package:likha/presentation/providers/sync_provider.dart';

class TeacherAssignmentListPage extends ConsumerStatefulWidget {
  final String classId;

  const TeacherAssignmentListPage({super.key, required this.classId});

  @override
  ConsumerState<TeacherAssignmentListPage> createState() =>
      _TeacherAssignmentListPageState();
}

class _TeacherAssignmentListPageState extends ConsumerState<TeacherAssignmentListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(assignmentProvider.notifier).loadAssignments(widget.classId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final assignmentState = ref.watch(assignmentProvider);

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
            ClassSectionHeader(
              title: 'Assignments',
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
                        builder: (_) => CreateAssignmentPage(classId: widget.classId),
                      ),
                    ).then((result) {
                      if (result == true) {
                        ref.read(assignmentProvider.notifier).loadAssignments(widget.classId);
                      }
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B2B2B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(
                      'Create',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: assignmentState.isLoading && assignmentState.assignments.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2B2B2B),
                        strokeWidth: 2.5,
                      ),
                    )
                  : assignmentState.assignments.isEmpty
                      ? const EmptyAssignmentListState()
                      : RefreshIndicator(
                          onRefresh: () => ref
                              .read(assignmentProvider.notifier)
                              .loadAssignments(widget.classId),
                          color: const Color(0xFF2B2B2B),
                          child: ListView.builder(
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
            ),
          ],
        ),
      ),
    );
  }
}
