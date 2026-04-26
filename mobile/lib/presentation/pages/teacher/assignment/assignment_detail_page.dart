import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/presentation/pages/teacher/assignment/assignment_submissions_page.dart';
import 'package:likha/presentation/pages/teacher/assignment/widgets/assignment_info_card.dart';
import 'package:likha/presentation/pages/teacher/assignment/widgets/assignment_instructions_card.dart';
import 'package:likha/presentation/pages/teacher/assignment/widgets/assignment_status_card.dart';
import 'package:likha/presentation/pages/teacher/assignment/widgets/assignment_submissions_card.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';
import 'package:likha/presentation/pages/shared/widgets/dialogs/app_dialogs.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/form_message.dart';

class AssignmentDetailPage extends ConsumerStatefulWidget {
  final String assignmentId;

  const AssignmentDetailPage({super.key, required this.assignmentId});

  @override
  ConsumerState<AssignmentDetailPage> createState() =>
      _AssignmentDetailPageState();
}

class _AssignmentDetailPageState extends ConsumerState<AssignmentDetailPage> {
  String? _formError;

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
    AppDialogs.showConfirmation(
      context: context,
      title: 'Publish Assignment',
      body: 'Publish "${assignment.title}"? Students will be able to see and submit to this assignment.',
      confirmLabel: 'Publish',
      onConfirm: () => ref.read(assignmentProvider.notifier).publishAssignment(widget.assignmentId),
    );
  }

  void _confirmUnpublish(Assignment assignment) {
    AppDialogs.showDestructive(
      context: context,
      title: 'Move to Draft',
      body: 'Move "${assignment.title}" back to draft? Students will no longer be able to access it.',
      confirmLabel: 'Move to Draft',
      onConfirm: () => ref.read(assignmentProvider.notifier).unpublishAssignment(widget.assignmentId),
    );
  }

  void _confirmDelete(Assignment assignment) {
    AppDialogs.showDestructive(
      context: context,
      title: 'Delete Assignment',
      body: 'Delete "${assignment.title}"? This cannot be undone.',
      confirmLabel: 'Delete',
      onConfirm: () => ref.read(assignmentProvider.notifier).deleteAssignment(widget.assignmentId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assignmentProvider);
    final assignment = state.currentAssignment;

    ref.listen<AssignmentState>(assignmentProvider, (prev, next) {
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        setState(() => _formError = null);
        ref.read(assignmentProvider.notifier).clearMessages();
        if (next.successMessage == 'Assignment deleted') {
          Navigator.pop(context, true);
        }
      }
      if (next.error != null && prev?.error != next.error) {
        setState(() => _formError = AppErrorMapper.toUserMessage(next.error));
        ref.read(assignmentProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.accentCharcoal),
        title: Text(
          assignment?.title ?? 'Assignment Detail',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.accentCharcoal,
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
                  case 'unpublish':
                    _confirmUnpublish(assignment);
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
                if (assignment.isPublished)
                  const PopupMenuItem(
                    value: 'unpublish',
                    child: Row(
                      children: [
                        Icon(Icons.unpublished_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Move to Draft'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_rounded,
                        color: AppColors.semanticError,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Delete',
                        style: TextStyle(color: AppColors.semanticError),
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
                color: AppColors.accentCharcoal,
                strokeWidth: 2.5,
              ),
            )
          : assignment == null
              ? const Center(
                  child: Text(
                    'Assignment not found',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.foregroundTertiary,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(assignmentProvider.notifier)
                      .loadAssignmentDetail(widget.assignmentId),
                  color: AppColors.accentCharcoal,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FormMessage(
                          message: _formError,
                          severity: MessageSeverity.error,
                        ),
                        if (_formError != null) const SizedBox(height: 12),
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
                          submissionType: assignment.allowsTextSubmission && assignment.allowsFileSubmission 
                              ? 'text_or_file' 
                              : assignment.allowsTextSubmission 
                                  ? 'text' 
                                  : 'file',
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