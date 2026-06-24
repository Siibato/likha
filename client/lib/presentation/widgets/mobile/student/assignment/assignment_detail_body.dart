import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/services/server_clock_service.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/file_opener.dart';
import 'package:likha/core/utils/formatters.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/domain/assignments/entities/submission_file.dart';
import 'package:likha/injection_container.dart';
import 'package:likha/presentation/controllers/student/assignment/assignment_detail_controller.dart';
import 'package:likha/presentation/providers/assignment/submission_provider.dart';
import 'package:likha/presentation/providers/assignment/file_upload_provider.dart';
import 'package:likha/presentation/widgets/mobile/student/assignment/assignment_feedback_card.dart';
import 'package:likha/presentation/widgets/mobile/student/assignment/assignment_files_card.dart';
import 'package:likha/presentation/widgets/mobile/student/assignment/assignment_instructions_card.dart';
import 'package:likha/presentation/widgets/mobile/student/assignment/assignment_new_attempt_button.dart';
import 'package:likha/presentation/widgets/mobile/student/assignment/assignment_returned_banner.dart';
import 'package:likha/presentation/widgets/mobile/student/assignment/assignment_submit_button.dart';
import 'package:likha/presentation/widgets/mobile/student/assignment/assignment_submission_card.dart';
import 'package:likha/presentation/widgets/mobile/student/assignment/assignment_submission_info.dart';
import 'package:likha/presentation/widgets/mobile/student/assignment/assignment_submitted_banner.dart';
import 'package:likha/presentation/widgets/mobile/student/assignment/assignment_text_input_card.dart';
import 'package:likha/presentation/widgets/shared/cards/score_display_card.dart';
import 'package:likha/presentation/widgets/shared/forms/form_message.dart';
import 'package:likha/presentation/widgets/shared/primitives/class_section_header.dart';

/// Body content for the student assignment detail page.
/// Owns the scrollable list, conditional UI branches, and file-open logic.
class AssignmentDetailBody extends ConsumerWidget {
  final AssignmentDetailController controller;
  final String assignmentId;
  final String assignmentTitle;
  final String instructions;
  final int totalPoints;
  final DateTime dueAt;
  final bool isNewAttempt;
  final String? submissionStatus;
  final int? score;
  final VoidCallback onNewAttempt;

  const AssignmentDetailBody({
    super.key,
    required this.controller,
    required this.assignmentId,
    required this.assignmentTitle,
    required this.instructions,
    required this.totalPoints,
    required this.dueAt,
    required this.isNewAttempt,
    this.submissionStatus,
    this.score,
    required this.onNewAttempt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(submissionProvider);
    final rawSubmission = state.currentSubmission;
    final submission =
        (!isNewAttempt && rawSubmission?.assignmentId == assignmentId)
            ? rawSubmission
            : null;

    _hydrateIfNeeded(submission);

    ref.listen<SubmissionState>(submissionProvider, (prev, next) {
      _handleProviderChange(context, ref, prev, next);
    });

    final effectiveStatus = submission?.status ?? submissionStatus;
    final isGraded = effectiveStatus == 'graded';
    final isSubmitted = effectiveStatus == 'submitted';
    final isOfflineSubmitted =
        !isNewAttempt && submissionStatus == 'submitted' && submission == null;
    final isDeadlinePassed = sl<ServerClockService>().now().isAfter(dueAt);

    final isViewMode =
        !isNewAttempt && (isSubmitted || isOfflineSubmitted) && !isGraded;
    final isReturnedEdit = effectiveStatus == 'returned';
    final canEdit = isNewAttempt ||
        (!isGraded &&
            !isViewMode &&
            (effectiveStatus == null ||
                effectiveStatus == 'draft' ||
                isReturnedEdit));
    final isLoading =
        (state.isLoading || controller.isCreatingSubmission) &&
            !isOfflineSubmitted;

    final pageTitle = isNewAttempt ? 'New Attempt' : 'Assignment Details';

    if (state.isLoading &&
        submission == null &&
        !isOfflineSubmitted &&
        !isNewAttempt) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.accentCharcoal,
          strokeWidth: 2.5,
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: ClassSectionHeader(
            title: pageTitle,
            showBackButton: true,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              FormMessage(
                message: controller.formError,
                severity: MessageSeverity.error,
              ),
              if (controller.formError != null) const SizedBox(height: 12),
              Text(
                assignmentTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentCharcoal,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              AssignmentInstructionsCard(
                instructions: instructions,
                totalPoints: totalPoints,
              ),
              if (isGraded) ...[
                const SizedBox(height: 16),
                if (submission != null && submission.score != null)
                  ScoreDisplayCard(
                    score: submission.score!,
                    totalPoints: totalPoints,
                    useBaseCardStyle: true,
                    gradedAt: submission.gradedAt,
                    formatDateTime: (dt) => formatDateTimeDisplay(dt),
                  )
                else if (score != null)
                  ScoreDisplayCard(
                    score: score!,
                    totalPoints: totalPoints,
                    useBaseCardStyle: true,
                  ),
              ],
              if (submission != null &&
                  submission.feedback != null &&
                  submission.feedback!.isNotEmpty) ...[
                const SizedBox(height: 16),
                if (submission.status == 'returned')
                  AssignmentReturnedBanner(feedback: submission.feedback!)
                else if (submission.status == 'graded')
                  AssignmentFeedbackCard(feedback: submission.feedback!)
              ],
              if (isViewMode) ...[
                const SizedBox(height: 24),
                const AssignmentSubmittedBanner(),
                if (submission != null) ...[
                  const SizedBox(height: 16),
                  AssignmentSubmissionCard(
                    submission: submission,
                    onOpenFile: (file) => _openFile(context, ref, file),
                    onSaveFile: controller.saveFile,
                  ),
                ],
                if (submission != null && submission.submittedAt != null) ...[
                  const SizedBox(height: 16),
                  AssignmentSubmissionInfo(
                      submittedAt: submission.submittedAt!),
                ],
                if (!isDeadlinePassed) ...[
                  const SizedBox(height: 24),
                  AssignmentNewAttemptButton(onPressed: onNewAttempt),
                ],
              ],
              if (canEdit) ...[
                if (controller.canSubmitText) ...[
                  const SizedBox(height: 16),
                  AssignmentTextInputCard(
                    controller: controller.submissionController,
                    isReadOnly: false,
                  ),
                ],
                if (controller.canSubmitFile) ...[
                  const SizedBox(height: 16),
                  AssignmentFilesCard(
                    files: submission?.files ?? [],
                    isReadOnly: false,
                    allowedFileTypes: controller.allowedFileTypes,
                    maxFileSizeMb: controller.maxFileSizeMb,
                    onUploadPressed: controller.pickAndUploadFile,
                    onDeleteFile: controller.deleteFile,
                  ),
                ],
                const SizedBox(height: 24),
                AssignmentSubmitButton(
                  isLoading: isLoading,
                  onPressed: controller.performSubmit,
                  text: isReturnedEdit
                      ? 'Re-submit Assignment'
                      : 'Submit Assignment',
                ),
              ],
              if (isGraded && submission != null) ...[
                const SizedBox(height: 16),
                AssignmentSubmissionCard(
                  submission: submission,
                  onOpenFile: (file) => _openFile(context, ref, file),
                  onSaveFile: controller.saveFile,
                ),
                if (submission.submittedAt != null) ...[
                  const SizedBox(height: 16),
                  AssignmentSubmissionInfo(
                      submittedAt: submission.submittedAt!),
                ],
              ],
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ],
    );
  }

  void _hydrateIfNeeded(AssignmentSubmission? submission) {
    if (!isNewAttempt &&
        submission != null &&
        submission.textContent != null &&
        controller.submissionController.document.toPlainText().trim().isEmpty) {
      controller.hydrateController(submission.textContent!);
    }

    if (!isNewAttempt &&
        submission == null &&
        submissionStatus == 'submitted' &&
        controller.submissionController.document.toPlainText().trim().isEmpty) {
      final id = controller.submissionId;
      if (id != null) {
        controller.loadOfflineSubmissionText(id);
      }
    }
  }

  void _handleProviderChange(
    BuildContext context,
    WidgetRef ref,
    SubmissionState? prev,
    SubmissionState next,
  ) {
    if (next.successMessage != null &&
        prev?.successMessage != next.successMessage) {
      controller.clearFormError();
      ref.read(submissionProvider.notifier).clearMessages();
      if (next.successMessage == 'Assignment submitted') {
        final isOffline = next.currentSubmission?.syncStatus != SyncStatus.synced;
        if (isOffline && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saved offline — will sync when connected'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        Navigator.pop(context, true);
      }
    }
    if (next.error != null && prev?.error != next.error) {
      final isEditablePage = !isNewAttempt &&
          submissionStatus != 'submitted' &&
          submissionStatus != 'graded';
      if (isEditablePage) {
        controller.setFormError(
            AppErrorMapper.toUserMessage(next.error));
      }
      ref.read(submissionProvider.notifier).clearMessages();
    }
  }

  Future<void> _openFile(BuildContext context, WidgetRef ref, SubmissionFile file) async {
    if (kIsWeb) {
      controller.setFormError('Opening file...');
      final bytes =
          await ref.read(fileUploadProvider.notifier).downloadFile(file.id);
      if (!context.mounted) return;
      if (bytes != null) {
        await openFileInBrowser(bytes, file.fileName);
        controller.clearFormError();
      } else {
        controller.setFormError('Failed to open file');
      }
      return;
    }

    if (file.localPath == null || file.localPath!.isEmpty) {
      controller.setFormError('File not cached. Downloading...');
      await controller.saveFile(file);
      return;
    }
    try {
      await openLocalFile(file.localPath!);
    } catch (e) {
      if (!context.mounted) return;
      controller.setFormError('Error opening file: $e');
    }
  }
}
