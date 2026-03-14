import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/snackbar_utils.dart';
import 'package:likha/domain/assignments/entities/submission_file.dart';
import 'package:likha/domain/assignments/usecases/grade_submission.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/styled_text_field.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/styled_button.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/base_card.dart';
import 'package:likha/presentation/pages/shared/widgets/primitives/status_badge.dart';
import 'package:likha/presentation/pages/shared/widgets/primitives/card_icon_slot.dart';
import 'package:likha/presentation/pages/shared/widgets/tokens/app_text_styles.dart';
import 'package:open_file/open_file.dart';

class GradeSubmissionPage extends ConsumerStatefulWidget {
  final String submissionId;
  final int totalPoints;

  const GradeSubmissionPage({
    super.key,
    required this.submissionId,
    required this.totalPoints,
  });

  @override
  ConsumerState<GradeSubmissionPage> createState() =>
      _GradeSubmissionPageState();
}

class _GradeSubmissionPageState extends ConsumerState<GradeSubmissionPage> {
  final _scoreController = TextEditingController();
  final _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scoreController.clear();
    _feedbackController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(assignmentProvider.notifier)
          .loadSubmissionDetail(widget.submissionId);
    });
  }

  void _prefillFormIfGraded() {
    final submission = ref.read(assignmentProvider).currentSubmission;
    if (submission == null) return;

    final newScore = submission.score?.toString() ?? '';
    if (_scoreController.text != newScore) {
      _scoreController.text = newScore;
    }

    final newFeedback = submission.feedback ?? '';
    if (_feedbackController.text != newFeedback) {
      _feedbackController.text = newFeedback;
    }
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
        ? 12
        : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} $hour:$minute $period';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _handleGrade() async {
    final score = int.tryParse(_scoreController.text.trim());
    if (score == null || score < 0 || score > widget.totalPoints) {
      context.showErrorSnackBar(
        'Score must be between 0 and ${widget.totalPoints}',
      );
      return;
    }

    final feedback = _feedbackController.text.trim();
    await ref
        .read(assignmentProvider.notifier)
        .gradeSubmission(
          GradeSubmissionParams(
            submissionId: widget.submissionId,
            score: score,
            feedback: feedback.isEmpty ? null : feedback,
          ),
        );
  }

  Future<void> _handleReturn() async {
    await ref
        .read(assignmentProvider.notifier)
        .returnSubmission(widget.submissionId);
  }

  /// Open file with system default app
  Future<void> _openFile(SubmissionFile file) async {
    if (file.localPath == null || file.localPath!.isEmpty) {
      // File path not available, offer to download
      if (!mounted) return;
      context.showWarningSnackBar('File not cached. Downloading...', durationMs: 2000);
      await _saveFile(file);
      return;
    }

    try {
      await OpenFile.open(file.localPath!);
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Error opening file: $e');
    }
  }

  /// Download file via provider (datasource handles caching)
  Future<void> _saveFile(SubmissionFile file) async {
    if (mounted) {
      context.showInfoSnackBar('Downloading ${file.fileName}...', durationMs: 3000);
    }

    // Provider's downloadFile() handles the download, caching, and reload (mirrors MaterialDetailPage._saveFile)
    await ref.read(assignmentProvider.notifier).downloadFile(file.id);

    if (!mounted) return;

    // Check if download succeeded
    final providerState = ref.read(assignmentProvider);
    if (providerState.error != null) {
      context.showErrorSnackBar('Failed to download file', durationMs: 3000);
    } else {
      context.showSuccessSnackBar('✓ Downloaded: ${file.fileName}', durationMs: 3000);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assignmentProvider);
    final submission = state.currentSubmission;

    // Prefill form if submission is already graded
    if (submission != null) {
      _prefillFormIfGraded();
    }

    ref.listen<AssignmentState>(assignmentProvider, (prev, next) {
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        context.showSuccessSnackBar(next.successMessage!);
        ref.read(assignmentProvider.notifier).clearMessages();
        if (next.successMessage == 'Submission graded' ||
            next.successMessage == 'Submission returned for revision') {
          ref
              .read(assignmentProvider.notifier)
              .loadSubmissionDetail(widget.submissionId);
        }
      }
      if (next.error != null && prev?.error != next.error) {
        context.showErrorSnackBar(next.error!);
        ref.read(assignmentProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.foregroundPrimary),
        title: Text(
          submission != null
              ? '${submission.studentName}\'s Submission'
              : 'Submission',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.foregroundPrimary,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: state.isLoading && submission == null
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.foregroundPrimary,
                strokeWidth: 2.5,
              ),
            )
          : submission == null
          ? const Center(child: Text('Submission not found'))
          : RefreshIndicator(
              color: AppColors.foregroundPrimary,
              onRefresh: () => ref
                  .read(assignmentProvider.notifier)
                  .loadSubmissionDetail(widget.submissionId),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatusBadge(submission.status, submission.isLate),
                    const SizedBox(height: 16),
                    if (submission.textContent != null &&
                        submission.textContent!.isNotEmpty) ...[
                      _buildSection(
                        'Text Content',
                        child: Text(
                          submission.textContent!,
                          style: const TextStyle(fontSize: 15, height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (submission.files.isNotEmpty) ...[
                      _buildSection(
                        'Files (${submission.files.length})',
                        child: Column(
                          children: submission.files
                              .map(
                                (file) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CardIconSlot.sm(
                                    icon: Icons.attach_file_rounded,
                                    iconColor: AppColors.foregroundSecondary,
                                  ),
                                  title: Text(file.fileName),
                                  subtitle: Text(
                                    _formatFileSize(file.fileSize),
                                  ),
                                  trailing: IconButton(
                                    icon: file.isCached
                                        ? const Icon(Icons.folder_open_rounded)
                                        : const Icon(Icons.download_rounded),
                                    onPressed: () => file.isCached
                                        ? _openFile(file)
                                        : _saveFile(file),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (submission.submittedAt != null)
                      Text(
                        'Submitted: ${_formatDateTime(submission.submittedAt!)}',
                        style: AppTextStyles.cardSubtitleMd,
                      ),
                    if (submission.score != null) ...[
                      const SizedBox(height: 16),
                      _buildSection(
                        'Current Grade',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${submission.score}/${widget.totalPoints}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.foregroundDark,
                              ),
                            ),
                            if (submission.feedback != null &&
                                submission.feedback!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  submission.feedback!,
                                  style: const TextStyle(
                                    color: AppColors.foregroundSecondary,
                                  ),
                                ),
                              ),
                            if (submission.gradedAt != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Graded: ${_formatDateTime(submission.gradedAt!)}',
                                  style: const TextStyle(
                                    color: AppColors.foregroundTertiary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (submission.status == 'submitted' ||
                        submission.status == 'returned' ||
                        submission.status == 'graded') ...[
                      const SizedBox(height: 24),
                      const Divider(height: 1, color: AppColors.borderLight),
                      const SizedBox(height: 20),
                      Text(
                        submission.status == 'graded'
                            ? 'Edit Grade'
                            : 'Grade Submission',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.foregroundDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      StyledTextField(
                        controller: _scoreController,
                        label: 'Score (out of ${widget.totalPoints})',
                        icon: Icons.star_outline_rounded,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty)
                            return 'Score is required';
                          final score = int.tryParse(value.trim());
                          if (score == null)
                            return 'Score must be a whole number';
                          if (score < 0 || score > widget.totalPoints)
                            return 'Score must be between 0 and ${widget.totalPoints}';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      StyledTextField(
                        controller: _feedbackController,
                        label: 'Feedback (optional)',
                        icon: Icons.comment_outlined,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: StyledButton(
                              text: 'Return',
                              isLoading: state.isLoading,
                              onPressed: _handleReturn,
                              variant: StyledButtonVariant.outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StyledButton(
                              text: submission.status == 'graded'
                                  ? 'Update Grade'
                                  : 'Grade',
                              isLoading: state.isLoading,
                              onPressed: _handleGrade,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusBadge(String status, bool isLate) {
    Color statusColor;
    switch (status) {
      case 'submitted':
        statusColor = AppColors.foregroundSecondary;
        break;
      case 'graded':
        statusColor = AppColors.semanticSuccess;
        break;
      case 'returned':
        statusColor = AppColors.deprecatedWarningYellow;
        break;
      default: // draft
        statusColor = AppColors.foregroundTertiary;
        break;
    }

    return Row(
      children: [
        StatusBadge(
          label: status[0].toUpperCase() + status.substring(1),
          color: statusColor,
          variant: BadgeVariant.outlined,
        ),
        if (isLate) ...[
          const SizedBox(width: 8),
          StatusBadge(
            label: 'Late',
            color: AppColors.semanticError,
            variant: BadgeVariant.outlined,
          ),
        ],
      ],
    );
  }

  Widget _buildSection(String title, {required Widget child}) {
    return BaseCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.cardTitleMd),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
