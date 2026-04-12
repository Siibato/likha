import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/desktop/teacher/assignment_submissions_desktop.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/markdown_display.dart';
import 'package:likha/presentation/pages/shared/widgets/dialogs/app_dialogs.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';

class AssignmentDetailDesktop extends ConsumerStatefulWidget {
  final String assignmentId;

  const AssignmentDetailDesktop({super.key, required this.assignmentId});

  @override
  ConsumerState<AssignmentDetailDesktop> createState() =>
      _AssignmentDetailDesktopState();
}

class _AssignmentDetailDesktopState
    extends ConsumerState<AssignmentDetailDesktop> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(assignmentProvider.notifier)
          .loadAssignmentDetail(widget.assignmentId);
    });
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatSubmissionType(String type) {
    switch (type) {
      case 'text_or_file':
        return 'Text or File';
      case 'text':
        return 'Text Only';
      case 'file':
        return 'File Only';
      default:
        return type;
    }
  }

  void _confirmPublish(Assignment assignment) {
    AppDialogs.showConfirmation(
      context: context,
      title: 'Publish Assignment',
      body:
          'Publish "${assignment.title}"? Students will be able to see and submit to this assignment.',
      confirmLabel: 'Publish',
      onConfirm: () => ref
          .read(assignmentProvider.notifier)
          .publishAssignment(widget.assignmentId),
    );
  }

  void _confirmUnpublish(Assignment assignment) {
    AppDialogs.showDestructive(
      context: context,
      title: 'Move to Draft',
      body:
          'Move "${assignment.title}" back to draft? Students will no longer be able to access it.',
      confirmLabel: 'Move to Draft',
      onConfirm: () => ref
          .read(assignmentProvider.notifier)
          .unpublishAssignment(widget.assignmentId),
    );
  }

  void _confirmDelete(Assignment assignment) {
    AppDialogs.showDestructive(
      context: context,
      title: 'Delete Assignment',
      body: 'Delete "${assignment.title}"? This cannot be undone.',
      confirmLabel: 'Delete',
      onConfirm: () => ref
          .read(assignmentProvider.notifier)
          .deleteAssignment(widget.assignmentId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assignmentProvider);
    final assignment = state.currentAssignment;

    ref.listen<AssignmentState>(assignmentProvider, (prev, next) {
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.semanticSuccess,
          ),
        );
        ref.read(assignmentProvider.notifier).clearMessages();

        if (next.successMessage == 'Assignment deleted') {
          Navigator.of(context).pop(true);
          return;
        }

        // Reload on publish/unpublish changes
        if (next.successMessage == 'Assignment published' ||
            next.successMessage == 'Assignment moved to draft') {
          ref
              .read(assignmentProvider.notifier)
              .loadAssignmentDetail(widget.assignmentId);
        }
      }

      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorMapper.toUserMessage(next.error) ?? 'An error occurred'),
            backgroundColor: AppColors.semanticError,
          ),
        );
        ref.read(assignmentProvider.notifier).clearMessages();
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
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppColors.foregroundDark),
              onSelected: (value) {
                switch (value) {
                  case 'publish':
                    _confirmPublish(assignment);
                    break;
                  case 'unpublish':
                    _confirmUnpublish(assignment);
                    break;
                  case 'delete':
                    _confirmDelete(assignment);
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: assignment.isPublished ? 'unpublish' : 'publish',
                  child: Row(
                    children: [
                      Icon(
                        assignment.isPublished
                            ? Icons.unpublished_rounded
                            : Icons.publish_rounded,
                        size: 18,
                        color: AppColors.foregroundSecondary,
                      ),
                      const SizedBox(width: 12),
                      Text(assignment.isPublished ? 'Unpublish' : 'Publish'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_rounded,
                          size: 18, color: AppColors.semanticError),
                      SizedBox(width: 12),
                      Text('Delete',
                          style: TextStyle(color: AppColors.semanticError)),
                    ],
                  ),
                ),
              ],
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
                        // Left column: assignment info + instructions
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStatusBadge(assignment),
                              const SizedBox(height: 24),
                              _buildInfoSection(assignment),
                              const SizedBox(height: 24),
                              _buildInstructionsSection(assignment),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Right column: submissions summary
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              _buildSubmissionsSummary(assignment),
                              const SizedBox(height: 16),
                              _buildViewSubmissionsButton(assignment),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildStatusBadge(Assignment assignment) {
    final isPublished = assignment.isPublished;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPublished
            ? const Color(0xFF28A745).withValues(alpha: 0.12)
            : AppColors.foregroundTertiary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isPublished ? 'Published' : 'Draft',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isPublished
              ? const Color(0xFF28A745)
              : AppColors.foregroundTertiary,
        ),
      ),
    );
  }

  Widget _buildInfoSection(Assignment assignment) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assignment Info',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundDark,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.stars_rounded,
            'Total Points',
            '${assignment.totalPoints}',
          ),
          _buildInfoRow(
            Icons.upload_file_rounded,
            'Submission Type',
            _formatSubmissionType(assignment.submissionType),
          ),
          _buildInfoRow(
            Icons.event_rounded,
            'Due Date',
            _formatDateTime(assignment.dueAt),
          ),
          _buildInfoRow(
            Icons.calendar_today_rounded,
            'Created',
            _formatDateTime(assignment.createdAt),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.foregroundTertiary),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.foregroundSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.foregroundDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsSection(Assignment assignment) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Instructions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundDark,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderLight),
          const SizedBox(height: 12),
          if (assignment.instructions.isNotEmpty)
            MarkdownDisplay(content: assignment.instructions)
          else
            const Text(
              'No instructions provided',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.foregroundTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubmissionsSummary(Assignment assignment) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Submissions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundDark,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow('Submitted', '${assignment.submissionCount}'),
          const SizedBox(height: 12),
          _buildStatRow('Graded', '${assignment.gradedCount}'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.foregroundSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.foregroundDark,
          ),
        ),
      ],
    );
  }

  Widget _buildViewSubmissionsButton(Assignment assignment) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AssignmentSubmissionsDesktop(
                assignmentId: widget.assignmentId,
                title: assignment.title,
                totalPoints: assignment.totalPoints,
              ),
            ),
          );
        },
        icon: const Icon(Icons.list_alt_rounded, size: 18),
        label: const Text('View Submissions'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.foregroundDark,
          side: const BorderSide(color: AppColors.borderLight),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
