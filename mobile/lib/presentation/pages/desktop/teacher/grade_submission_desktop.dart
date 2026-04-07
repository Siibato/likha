import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/assignments/entities/submission_file.dart';
import 'package:likha/domain/assignments/usecases/grade_submission.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/form_message.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';

class GradeSubmissionDesktop extends ConsumerStatefulWidget {
  final String submissionId;
  final int totalPoints;

  const GradeSubmissionDesktop({
    super.key,
    required this.submissionId,
    required this.totalPoints,
  });

  @override
  ConsumerState<GradeSubmissionDesktop> createState() =>
      _GradeSubmissionDesktopState();
}

class _GradeSubmissionDesktopState
    extends ConsumerState<GradeSubmissionDesktop> {
  final _scoreController = TextEditingController();
  final _feedbackController = TextEditingController();
  String? _formError;
  bool _formPrefilled = false;

  @override
  void initState() {
    super.initState();
    _scoreController.clear();
    _feedbackController.clear();
    _formPrefilled = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(assignmentProvider.notifier)
          .loadSubmissionDetail(widget.submissionId);
    });
  }

  void _prefillFormIfGraded() {
    if (_formPrefilled) return;

    final submission = ref.read(assignmentProvider).currentSubmission;
    if (submission == null) return;

    _scoreController.text = submission.score?.toString() ?? '';
    _feedbackController.text = submission.feedback ?? '';
    _formPrefilled = true;
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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
      setState(
          () => _formError = 'Score must be between 0 and ${widget.totalPoints}');
      return;
    }

    setState(() => _formError = null);
    final feedback = _feedbackController.text.trim();
    await ref.read(assignmentProvider.notifier).gradeSubmission(
          GradeSubmissionParams(
            submissionId: widget.submissionId,
            score: score,
            feedback: feedback.isEmpty ? null : feedback,
          ),
        );
  }

  Future<void> _downloadFile(SubmissionFile file) async {
    await ref.read(assignmentProvider.notifier).downloadFile(file.id);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assignmentProvider);
    final submission = state.currentSubmission;

    if (submission != null) {
      _prefillFormIfGraded();
    }

    ref.listen<AssignmentState>(assignmentProvider, (prev, next) {
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        ref.read(assignmentProvider.notifier).clearMessages();
        if (next.successMessage == 'Submission graded') {
          ref
              .read(assignmentProvider.notifier)
              .loadSubmissionDetail(widget.submissionId);
        }
      }
      if (next.error != null && prev?.error != next.error) {
        setState(() => _formError = AppErrorMapper.toUserMessage(next.error));
        ref.read(assignmentProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: submission?.studentName ?? 'Submission',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        body: state.isLoading && submission == null
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.foregroundPrimary,
                  strokeWidth: 2.5,
                ),
              )
            : submission == null
                ? const Center(
                    child: Text(
                      'Submission not found',
                      style: TextStyle(color: AppColors.foregroundTertiary),
                    ),
                  )
                : SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: submission content
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStatusBadges(
                                  submission.status, submission.isLate),
                              const SizedBox(height: 24),
                              if (submission.textContent != null &&
                                  submission.textContent!.isNotEmpty) ...[
                                _buildTextContentSection(
                                    submission.textContent!),
                                const SizedBox(height: 24),
                              ],
                              if (submission.files.isNotEmpty) ...[
                                _buildFilesSection(submission.files),
                                const SizedBox(height: 24),
                              ],
                              if (submission.submittedAt != null)
                                Text(
                                  'Submitted: ${_formatDateTime(submission.submittedAt!)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.foregroundTertiary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Right: grading panel
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              if (submission.score != null) ...[
                                _buildCurrentGradeCard(submission),
                                const SizedBox(height: 16),
                              ],
                              if (submission.status == 'submitted' ||
                                  submission.status == 'returned' ||
                                  submission.status == 'graded')
                                _buildGradingForm(state.isLoading, submission),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildStatusBadges(String status, bool isLate) {
    Color statusColor;
    switch (status) {
      case 'submitted':
        statusColor = AppColors.foregroundSecondary;
        break;
      case 'graded':
        statusColor = const Color(0xFF28A745);
        break;
      case 'returned':
        statusColor = const Color(0xFFFFA726);
        break;
      default:
        statusColor = AppColors.foregroundTertiary;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status[0].toUpperCase() + status.substring(1),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ),
        if (isLate) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.semanticError.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Late',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.semanticError,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextContentSection(String textContent) {
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
            'Text Content',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundDark,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderLight),
          const SizedBox(height: 12),
          SelectableText(
            textContent,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.foregroundSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesSection(List<SubmissionFile> files) {
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
          Text(
            'Files (${files.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundDark,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderLight),
          const SizedBox(height: 8),
          ...files.map((file) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.attach_file_rounded,
                    size: 18,
                    color: AppColors.foregroundSecondary,
                  ),
                ),
                title: Text(
                  file.fileName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.foregroundDark,
                  ),
                ),
                subtitle: Text(
                  _formatFileSize(file.fileSize),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.foregroundTertiary,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.download_rounded, size: 20),
                  color: AppColors.foregroundSecondary,
                  onPressed: () => _downloadFile(file),
                  tooltip: 'Download',
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCurrentGradeCard(dynamic submission) {
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
            'Current Grade',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${submission.score}/${widget.totalPoints}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.foregroundDark,
            ),
          ),
          if (submission.feedback != null &&
              submission.feedback!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              submission.feedback!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.foregroundSecondary,
              ),
            ),
          ],
          if (submission.gradedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Graded: ${_formatDateTime(submission.gradedAt!)}',
              style: const TextStyle(
                color: AppColors.foregroundTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGradingForm(bool isLoading, dynamic submission) {
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
          Text(
            submission.status == 'graded' ? 'Edit Grade' : 'Grade Submission',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundDark,
            ),
          ),
          const SizedBox(height: 16),
          FormMessage(
            message: _formError,
            severity: MessageSeverity.error,
          ),
          if (_formError != null) const SizedBox(height: 12),
          TextFormField(
            controller: _scoreController,
            decoration: _inputDecoration('Score (out of ${widget.totalPoints})'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() => _formError = null),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _feedbackController,
            decoration: _inputDecoration('Feedback (optional)'),
            maxLines: 4,
            minLines: 2,
            onChanged: (_) => setState(() => _formError = null),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: isLoading ? null : _handleGrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.foregroundPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      submission.status == 'graded' ? 'Update Grade' : 'Grade',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontSize: 14,
        color: AppColors.foregroundSecondary,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppColors.foregroundPrimary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
