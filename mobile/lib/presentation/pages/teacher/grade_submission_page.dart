import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/utils/snackbar_utils.dart';
import 'package:likha/domain/assignments/usecases/grade_submission.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';
import 'package:path_provider/path_provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(assignmentProvider.notifier)
          .loadSubmissionDetail(widget.submissionId);
    });
  }

  void _prefillFormIfGraded() {
    final submission = ref.read(assignmentProvider).currentSubmission;
    if (submission?.score != null && _scoreController.text.isEmpty) {
      _scoreController.text = submission!.score.toString();
    }
    if (submission?.feedback != null && _feedbackController.text.isEmpty) {
      _feedbackController.text = submission!.feedback!;
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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
      context.showErrorSnackBar('Score must be between 0 and ${widget.totalPoints}');
      return;
    }

    final feedback = _feedbackController.text.trim();
    await ref.read(assignmentProvider.notifier).gradeSubmission(
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

  Future<void> _downloadFile(String fileId, String fileName) async {
    final bytes =
        await ref.read(assignmentProvider.notifier).downloadFile(fileId);
    if (bytes == null || !mounted) return;

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      context.showSuccessSnackBar('File saved to ${file.path}');
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Failed to save file: $e');
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
      appBar: AppBar(
        title: Text(submission != null
            ? '${submission.studentName}\'s Submission'
            : 'Submission'),
      ),
      body: state.isLoading && submission == null
          ? const Center(child: CircularProgressIndicator())
          : submission == null
              ? const Center(child: Text('Submission not found'))
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(assignmentProvider.notifier)
                      .loadSubmissionDetail(widget.submissionId),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
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
                              style:
                                  const TextStyle(fontSize: 15, height: 1.5),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (submission.files.isNotEmpty) ...[
                          _buildSection(
                            'Files (${submission.files.length})',
                            child: Column(
                              children: submission.files
                                  .map((file) => ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: const Icon(
                                            Icons.attach_file),
                                        title: Text(file.fileName),
                                        subtitle: Text(
                                            _formatFileSize(file.fileSize)),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.download),
                                          onPressed: () => _downloadFile(
                                              file.id, file.fileName),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (submission.submittedAt != null)
                          Text(
                            'Submitted: ${_formatDateTime(submission.submittedAt!)}',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13),
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
                                  ),
                                ),
                                if (submission.feedback != null &&
                                    submission.feedback!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      submission.feedback!,
                                      style: TextStyle(
                                          color: Colors.grey[700]),
                                    ),
                                  ),
                                if (submission.gradedAt != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Graded: ${_formatDateTime(submission.gradedAt!)}',
                                      style: TextStyle(
                                        color: Colors.grey[500],
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
                          const Divider(),
                          const SizedBox(height: 16),
                          Text(
                            submission.status == 'graded'
                                ? 'Edit Grade'
                                : 'Grade Submission',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _scoreController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText:
                                  'Score (out of ${widget.totalPoints})',
                              prefixIcon: const Icon(Icons.star),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _feedbackController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Feedback (optional)',
                              prefixIcon: const Icon(Icons.comment),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: state.isLoading
                                      ? null
                                      : _handleReturn,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    foregroundColor: Colors.orange,
                                    side: const BorderSide(
                                        color: Colors.orange),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Return'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: state.isLoading
                                      ? null
                                      : _handleGrade,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: state.isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child:
                                              CircularProgressIndicator(
                                                  strokeWidth: 2),
                                        )
                                      : Text(submission.status == 'graded'
                                          ? 'Update Grade'
                                          : 'Grade'),
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
    Color color;
    switch (status) {
      case 'draft':
        color = Colors.grey;
        break;
      case 'submitted':
        color = Colors.blue;
        break;
      case 'graded':
        color = Colors.green;
        break;
      case 'returned':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            status[0].toUpperCase() + status.substring(1),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (isLate) ...[
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: const Text(
              'Late',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSection(String title, {required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Divider(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
