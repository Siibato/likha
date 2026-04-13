import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/utils/snackbar_utils.dart';
import 'package:likha/presentation/pages/teacher/grade_submission_page.dart';
import 'package:likha/presentation/pages/teacher/widgets/empty_submissions_state.dart';
import 'package:likha/presentation/pages/teacher/widgets/submission_card.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';

class AssignmentSubmissionsPage extends ConsumerStatefulWidget {
  final String assignmentId;
  final String assignmentTitle;
  final int totalPoints;

  const AssignmentSubmissionsPage({
    super.key,
    required this.assignmentId,
    required this.assignmentTitle,
    required this.totalPoints,
  });

  @override
  ConsumerState<AssignmentSubmissionsPage> createState() =>
      _AssignmentSubmissionsPageState();
}

class _AssignmentSubmissionsPageState
    extends ConsumerState<AssignmentSubmissionsPage> {
  bool _isDownloadingAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(assignmentProvider.notifier)
          .loadSubmissions(widget.assignmentId);
    });
  }

  Future<void> _downloadAll() async {
    setState(() => _isDownloadingAll = true);
    context.showInfoSnackBar('Downloading submission files...', durationMs: 60000);

    final (count, totalUncached) = await ref.read(assignmentProvider.notifier).downloadAllSubmissionFiles();

    if (!mounted) return;
    setState(() => _isDownloadingAll = false);

    // Dismiss the info snackbar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final error = ref.read(assignmentProvider).error;
    if (error != null) {
      context.showErrorSnackBar(AppErrorMapper.toUserMessage(error) ?? 'Download failed');
      ref.read(assignmentProvider.notifier).clearMessages();
    } else if (count > 0) {
      context.showSuccessSnackBar('Downloaded $count file(s). All submissions viewable offline.');
    } else if (totalUncached > 0) {
      context.showWarningSnackBar('Some files could not be downloaded. Please try again.');
    } else {
      context.showInfoSnackBar('All files already downloaded.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assignmentProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.foregroundPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Submissions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.foregroundPrimary,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              widget.assignmentTitle,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.foregroundTertiary,
              ),
            ),
          ],
        ),
        actions: const [],
      ),
      body: state.isLoading && state.submissions.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.foregroundPrimary,
                strokeWidth: 2.5,
              ),
            )
          : state.submissions.isEmpty
              ? const EmptySubmissionsState()
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(assignmentProvider.notifier)
                      .loadSubmissions(widget.assignmentId),
                  color: AppColors.foregroundPrimary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: state.submissions.length,
                    itemBuilder: (context, index) {
                      final submission = state.submissions[index];

                      return SubmissionCard(
                        studentName: submission.studentName,
                        studentUsername: submission.studentUsername,
                        status: submission.status,
                        score: submission.score,
                        totalPoints: widget.totalPoints,
                        submittedAt: submission.submittedAt,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GradeSubmissionPage(
                              submissionId: submission.id,
                              totalPoints: widget.totalPoints,
                            ),
                          ),
                        ).then((_) => ref
                            .read(assignmentProvider.notifier)
                            .loadSubmissions(widget.assignmentId)),
                      );
                    },
                  ),
                ),
      bottomNavigationBar: state.submissions.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
              ),
              child: FilledButton(
                onPressed: _isDownloadingAll ? null : _downloadAll,
                style: FilledButton.styleFrom(
                  backgroundColor: _isDownloadingAll
                      ? const Color(0xFFCCCCCC)
                      : const Color(0xFF2B2B2B),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isDownloadingAll
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.download_for_offline_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Download All Files',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
    );
  }
}