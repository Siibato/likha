import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/pages/student/widgets/student_header.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';
import 'package:path_provider/path_provider.dart';

class AssignmentResultPage extends ConsumerStatefulWidget {
  final String assignmentId;
  final String assignmentTitle;
  final int totalPoints;

  const AssignmentResultPage({
    super.key,
    required this.assignmentId,
    required this.assignmentTitle,
    required this.totalPoints,
  });

  @override
  ConsumerState<AssignmentResultPage> createState() =>
      _AssignmentResultPageState();
}

class _AssignmentResultPageState extends ConsumerState<AssignmentResultPage> {
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
      'Dec'
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

  Future<void> _downloadFile(String fileId, String fileName) async {
    final bytes =
        await ref.read(assignmentProvider.notifier).downloadFile(fileId);
    if (bytes == null || !mounted) return;

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File saved to ${file.path}'),
          backgroundColor: const Color(0xFF34A853),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save file: $e'),
          backgroundColor: const Color(0xFFEA4335),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assignmentProvider);
    final submission = state.currentSubmission;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: state.isLoading && submission == null
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2B2B2B),
                  strokeWidth: 2.5,
                ),
              )
            : submission == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.assignment_outlined,
                            size: 64,
                            color: Color(0xFFCCCCCC),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No submission found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: StudentHeader(title: widget.assignmentTitle),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.all(24),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            if (submission.score != null)
                              _buildScoreCard(submission),
                            if (submission.feedback != null &&
                                submission.feedback!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildFeedbackCard(submission.feedback!),
                            ],
                            if (submission.status != 'graded') ...[
                              const SizedBox(height: 16),
                              _buildStatusInfo(
                                  submission.status, submission.isLate),
                            ],
                            if (submission.textContent != null &&
                                submission.textContent!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildResponseCard(submission.textContent!),
                            ],
                            if (submission.files.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildFilesCard(submission.files),
                            ],
                            if (submission.submittedAt != null) ...[
                              const SizedBox(height: 16),
                              _buildSubmissionInfo(
                                  submission.submittedAt!, submission.isLate),
                            ],
                            const SizedBox(height: 40),
                          ]),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildScoreCard(submission) {
    final percentage = widget.totalPoints > 0
        ? (submission.score! / widget.totalPoints * 100)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(
              'Your Score',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${submission.score}',
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2B2B2B),
                    letterSpacing: -1.5,
                  ),
                ),
                Text(
                  ' / ${widget.totalPoints}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8ED),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFFBD59).withOpacity(0.3),
                ),
              ),
              child: Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFBD59),
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: widget.totalPoints > 0
                    ? submission.score! / widget.totalPoints
                    : 0,
                minHeight: 10,
                backgroundColor: const Color(0xFFF0F0F0),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFFFFBD59)),
              ),
            ),
            if (submission.gradedAt != null) ...[
              const SizedBox(height: 16),
              Text(
                'Graded: ${_formatDateTime(submission.gradedAt!)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(String feedback) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Teacher Feedback',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF202020),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: const Color(0xFFF0F0F0),
            ),
            const SizedBox(height: 12),
            Text(
              feedback,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Color(0xFF2B2B2B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseCard(String textContent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Response',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF202020),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: const Color(0xFFF0F0F0),
            ),
            const SizedBox(height: 12),
            Text(
              textContent,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Color(0xFF2B2B2B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilesCard(List files) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Submitted Files',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF202020),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: const Color(0xFFF0F0F0),
            ),
            const SizedBox(height: 8),
            ...files.map((file) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.attach_file_rounded,
                      color: Color(0xFF666666),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    file.fileName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2B2B2B),
                    ),
                  ),
                  subtitle: Text(
                    _formatFileSize(file.fileSize),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.download_rounded,
                      color: Color(0xFFFFBD59),
                    ),
                    onPressed: () => _downloadFile(file.id, file.fileName),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusInfo(String status, bool isLate) {
    String label;
    IconData icon;

    switch (status) {
      case 'submitted':
        label = 'Submitted - Waiting for teacher to grade';
        icon = Icons.hourglass_bottom_rounded;
        break;
      case 'returned':
        label = 'Returned for revision';
        icon = Icons.replay_rounded;
        break;
      default:
        label = status;
        icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF666666), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF2B2B2B),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionInfo(DateTime submittedAt, bool isLate) {
    return Center(
      child: Text(
        'Submitted: ${_formatDateTime(submittedAt)}${isLate ? ' (Late)' : ''}',
        style: const TextStyle(
          color: Color(0xFF999999),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}