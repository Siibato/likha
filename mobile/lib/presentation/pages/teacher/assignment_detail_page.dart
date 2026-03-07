import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/utils/snackbar_utils.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/presentation/pages/teacher/assignment_submissions_page.dart';
import 'package:likha/presentation/pages/teacher/widgets/assignment_info_card.dart';
import 'package:likha/presentation/pages/teacher/widgets/assignment_instructions_card.dart';
import 'package:likha/presentation/pages/teacher/widgets/assignment_status_card.dart';
import 'package:likha/presentation/pages/teacher/widgets/assignment_submissions_card.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';

class AssignmentDetailPage extends ConsumerStatefulWidget {
  final String assignmentId;

  const AssignmentDetailPage({super.key, required this.assignmentId});

  @override
  ConsumerState<AssignmentDetailPage> createState() =>
      _AssignmentDetailPageState();
}

class _AssignmentDetailPageState extends ConsumerState<AssignmentDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(assignmentProvider.notifier)
          .loadAssignmentDetail(widget.assignmentId);
    });
  }

  void _confirmPublish(Assignment assignment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Publish Assignment',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Publish "${assignment.title}"? Students will be able to see and submit to this assignment.',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF666666),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(assignmentProvider.notifier)
                  .publishAssignment(widget.assignmentId);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2B2B2B),
            ),
            child: const Text(
              'Publish',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Assignment assignment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete Assignment',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Delete "${assignment.title}"? This cannot be undone.',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF666666),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(assignmentProvider.notifier)
                  .deleteAssignment(widget.assignmentId);
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Color(0xFFEF5350),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assignmentProvider);
    final assignment = state.currentAssignment;

    ref.listen<AssignmentState>(assignmentProvider, (prev, next) {
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        context.showSuccessSnackBar(next.successMessage!);
        ref.read(assignmentProvider.notifier).clearMessages();
        if (next.successMessage == 'Assignment deleted') {
          Navigator.pop(context, true);
        }
      }
      if (next.error != null && prev?.error != next.error) {
        context.showErrorSnackBar(next.error!);
        ref.read(assignmentProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2B2B2B)),
        title: Text(
          assignment?.title ?? 'Assignment Detail',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B2B),
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          if (assignment != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'submissions':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AssignmentSubmissionsPage(
                          assignmentId: widget.assignmentId,
                          assignmentTitle: assignment.title,
                          totalPoints: assignment.totalPoints,
                        ),
                      ),
                    );
                    break;
                  case 'publish':
                    _confirmPublish(assignment);
                    break;
                  case 'delete':
                    _confirmDelete(assignment);
                    break;
                }
              },
              itemBuilder: (context) => [
                if (assignment.isPublished)
                  const PopupMenuItem(
                    value: 'submissions',
                    child: Row(
                      children: [
                        Icon(
                          Icons.assignment_turned_in_rounded,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text('Submissions'),
                      ],
                    ),
                  ),
                if (!assignment.isPublished)
                  const PopupMenuItem(
                    value: 'publish',
                    child: Row(
                      children: [
                        Icon(Icons.publish_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Publish'),
                      ],
                    ),
                  ),
                if (!assignment.isPublished)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_rounded,
                          color: Color(0xFFEF5350),
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Delete',
                          style: TextStyle(color: Color(0xFFEF5350)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: state.isLoading && assignment == null
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2B2B2B),
                strokeWidth: 2.5,
              ),
            )
          : assignment == null
              ? const Center(
                  child: Text(
                    'Assignment not found',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF999999),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(assignmentProvider.notifier)
                      .loadAssignmentDetail(widget.assignmentId),
                  color: const Color(0xFF2B2B2B),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AssignmentStatusCard(
                          isPublished: assignment.isPublished,
                          dueAt: assignment.dueAt,
                          onTap: !assignment.isPublished
                              ? () => _confirmPublish(assignment)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        AssignmentInfoCard(
                          totalPoints: assignment.totalPoints,
                          submissionType: assignment.submissionType,
                          allowedFileTypes: assignment.allowedFileTypes,
                          maxFileSizeMb: assignment.maxFileSizeMb,
                          dueAt: assignment.dueAt,
                          createdAt: assignment.createdAt,
                        ),
                        const SizedBox(height: 16),
                        if (assignment.isPublished) ...[
                          AssignmentSubmissionsCard(
                            submissionCount: assignment.submissionCount,
                            gradedCount: assignment.gradedCount,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AssignmentSubmissionsPage(
                                  assignmentId: widget.assignmentId,
                                  assignmentTitle: assignment.title,
                                  totalPoints: assignment.totalPoints,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        AssignmentInstructionsCard(
                          instructions: assignment.instructions,
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}