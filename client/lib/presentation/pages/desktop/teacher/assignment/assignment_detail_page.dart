import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/presentation/layouts/desktop/desktop_page_scaffold.dart';
import 'package:likha/presentation/providers/assignment/assignment_detail_provider.dart';
import 'package:likha/presentation/providers/assignment/assignment_list_provider.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assignment/assignment_info_section.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assignment/assignment_instructions_section.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assignment/assignment_status_badge.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assignment/assignment_submissions_summary.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assignment/assignment_actions_menu.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assignment/assignment_view_submissions_button.dart';

class AssignmentDetailPage extends ConsumerStatefulWidget {
  final String assignmentId;

  const AssignmentDetailPage({super.key, required this.assignmentId});

  @override
  ConsumerState<AssignmentDetailPage> createState() =>
      _AssignmentDetailPageState();
}

class _AssignmentDetailPageState
    extends ConsumerState<AssignmentDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(assignmentDetailProvider.notifier)
          .loadAssignmentDetail(widget.assignmentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assignmentDetailProvider);
    final assignment = state.currentAssignment;

    ref.listen<AssignmentListState>(assignmentListProvider, (prev, next) {
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.semanticSuccess,
          ),
        );
        ref.read(assignmentListProvider.notifier).clearMessages();

        if (next.successMessage == 'Assignment deleted') {
          Navigator.of(context).pop(true);
          return;
        }
      }

      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorMapper.toUserMessage(next.error) ?? 'An error occurred'),
            backgroundColor: AppColors.semanticError,
          ),
        );
        ref.read(assignmentListProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: assignment?.title ?? 'Assignment Detail',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        actions: [
          if (assignment != null)
            AssignmentActionsMenu(
              assignment: assignment,
              assignmentId: widget.assignmentId,
            ),
        ],
        body: state.isLoading && assignment == null
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.foregroundPrimary,
                  strokeWidth: 2.5,
                ),
              )
            : assignment == null
                ? const Center(
                    child: Text(
                      'Assignment not found',
                      style: TextStyle(color: AppColors.foregroundTertiary),
                    ),
                  )
                : SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AssignmentStatusBadge(
                                  isPublished: assignment.isPublished),
                              const SizedBox(height: 24),
                              AssignmentInfoSection(assignment: assignment),
                              const SizedBox(height: 24),
                              AssignmentInstructionsSection(
                                  instructions: assignment.instructions),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              AssignmentSubmissionsSummary(
                                submissionCount: assignment.submissionCount,
                                gradedCount: assignment.gradedCount,
                              ),
                              const SizedBox(height: 16),
                              AssignmentViewSubmissionsButton(
                                assignmentId: widget.assignmentId,
                                title: assignment.title,
                                totalPoints: assignment.totalPoints,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
