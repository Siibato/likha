import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/domain/assignments/usecases/create_submission.dart';
import 'package:likha/domain/assignments/usecases/upload_file.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/pages/student/widgets/assignment_instructions_card.dart';
import 'package:likha/presentation/pages/student/widgets/assignment_returned_banner.dart';
import 'package:likha/presentation/pages/student/widgets/assignment_text_input_card.dart';
import 'package:likha/presentation/pages/student/widgets/assignment_files_card.dart';
import 'package:likha/presentation/pages/student/widgets/assignment_submit_button.dart';
import 'package:likha/presentation/pages/student/widgets/assignment_submitted_banner.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';
import 'package:path_provider/path_provider.dart';

class AssignmentDetailPage extends ConsumerStatefulWidget {
  final String assignmentId;
  final String assignmentTitle;
  final String instructions;
  final String submissionType;
  final int totalPoints;
  final String? allowedFileTypes;
  final int? maxFileSizeMb;
  final String? submissionId;
  final int? score;
  final String? submissionStatus;

  const AssignmentDetailPage({
    super.key,
    required this.assignmentId,
    required this.assignmentTitle,
    required this.instructions,
    required this.submissionType,
    required this.totalPoints,
    this.allowedFileTypes,
    this.maxFileSizeMb,
    this.submissionId,
    this.score,
    this.submissionStatus,
  });

  @override
  ConsumerState<AssignmentDetailPage> createState() =>
      _AssignmentDetailPageState();
}

class _AssignmentDetailPageState extends ConsumerState<AssignmentDetailPage> {
  final _textController = TextEditingController();
  String? _submissionId;
  bool _isCreatingSubmission = false;

  @override
  void initState() {
    super.initState();
    // Load existing submission if submissionId is provided
    if (widget.submissionId != null) {
      _submissionId = widget.submissionId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(assignmentProvider.notifier)
            .loadSubmissionDetail(widget.submissionId!);
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  bool get _canSubmitText =>
      widget.submissionType == 'text' ||
      widget.submissionType == 'text_or_file';

  bool get _canSubmitFile =>
      widget.submissionType == 'file' ||
      widget.submissionType == 'text_or_file';

  Future<void> _createSubmission() async {
    setState(() => _isCreatingSubmission = true);

    await ref.read(assignmentProvider.notifier).createSubmission(
          CreateSubmissionParams(
            assignmentId: widget.assignmentId,
            textContent: _canSubmitText ? _textController.text.trim() : null,
          ),
        );

    if (!mounted) return;
    final state = ref.read(assignmentProvider);
    if (state.currentSubmission != null && state.error == null) {
      setState(() {
        _submissionId = state.currentSubmission!.id;
        _isCreatingSubmission = false;
      });

      if (state.currentSubmission!.textContent != null &&
          _textController.text.isEmpty) {
        _textController.text = state.currentSubmission!.textContent!;
      }
    } else {
      setState(() => _isCreatingSubmission = false);
    }
  }

  Future<void> _pickAndUploadFile() async {
    if (_submissionId == null) {
      await _createSubmission();
      if (_submissionId == null) return;
    }

    List<String>? allowedExtensions;
    if (widget.allowedFileTypes != null &&
        widget.allowedFileTypes!.isNotEmpty) {
      allowedExtensions =
          widget.allowedFileTypes!.split(',').map((e) => e.trim()).toList();
    }

    final result = await FilePicker.platform.pickFiles(
      type: allowedExtensions != null ? FileType.custom : FileType.any,
      allowedExtensions: allowedExtensions,
    );

    if (result == null || result.files.isEmpty || !mounted) return;

    final file = result.files.first;
    if (file.path == null) return;

    if (widget.maxFileSizeMb != null) {
      final fileSizeMb = file.size / (1024 * 1024);
      if (fileSizeMb > widget.maxFileSizeMb!) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'File too large. Max size is ${widget.maxFileSizeMb} MB'),
            backgroundColor: const Color(0xFFEA4335),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }
    }

    await ref.read(assignmentProvider.notifier).uploadFile(
          UploadFileParams(
            submissionId: _submissionId!,
            filePath: file.path!,
            fileName: file.name,
          ),
        );

    if (!mounted) return;
    ref
        .read(assignmentProvider.notifier)
        .loadSubmissionDetail(_submissionId!);
  }

  Future<void> _handleSubmit() async {
    if (_submissionId == null) {
      await _createSubmission();
      if (_submissionId == null) return;
    }

    await ref
        .read(assignmentProvider.notifier)
        .submitAssignment(_submissionId!);
  }

  Future<void> _deleteFile(String fileId) async {
    await ref.read(assignmentProvider.notifier).deleteSubmissionFile(fileId);

    if (_submissionId != null && mounted) {
      ref
          .read(assignmentProvider.notifier)
          .loadSubmissionDetail(_submissionId!);
    }
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assignmentProvider);
    final submission = state.currentSubmission;

    // Prefill text content if submission exists
    if (submission != null &&
        submission.textContent != null &&
        _textController.text.isEmpty) {
      _textController.text = submission.textContent!;
    }

    ref.listen<AssignmentState>(assignmentProvider, (prev, next) {
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: const Color(0xFF34A853),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        ref.read(assignmentProvider.notifier).clearMessages();
        if (next.successMessage == 'Assignment submitted') {
          Navigator.pop(context, true);
        }
      }
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: const Color(0xFFEA4335),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        ref.read(assignmentProvider.notifier).clearMessages();
      }
    });

    // Use submission status from loaded data, or fall back to initial status from widget
    final effectiveStatus = submission?.status ?? widget.submissionStatus;
    final isSubmitted = effectiveStatus == 'submitted';
    final isGraded = effectiveStatus == 'graded';
    final isReadOnly = isSubmitted || isGraded;
    final canEdit = !isReadOnly;
    final isLoading = state.isLoading || _isCreatingSubmission;

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
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: ClassSectionHeader(
                      title: 'Assignment Details',
                      showBackButton: true,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Assignment Title
                        Text(
                          widget.assignmentTitle,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2B2B2B),
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Instructions
                        AssignmentInstructionsCard(
                          instructions: widget.instructions,
                          totalPoints: widget.totalPoints,
                        ),

                        // Graded view - show score first
                        if (isGraded) ...[
                          const SizedBox(height: 16),
                          if (submission != null && submission.score != null)
                            _buildScoreCard(submission)
                          else if (widget.score != null)
                            _buildScoreCardSimple(widget.score!),
                        ],

                        // Feedback for graded or returned
                        if (submission != null && submission.feedback != null && submission.feedback!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          if (submission.status == 'returned')
                            AssignmentReturnedBanner(feedback: submission.feedback!)
                          else if (submission.status == 'graded')
                            _buildFeedbackCard(submission.feedback!)
                        ],

                        // Editable form (for draft or returned)
                        if (_canSubmitText && canEdit) ...[
                          const SizedBox(height: 16),
                          AssignmentTextInputCard(
                            controller: _textController,
                            isReadOnly: false,
                          ),
                        ],
                        if (_canSubmitFile && canEdit) ...[
                          const SizedBox(height: 16),
                          AssignmentFilesCard(
                            files: submission?.files ?? [],
                            isReadOnly: false,
                            allowedFileTypes: widget.allowedFileTypes,
                            maxFileSizeMb: widget.maxFileSizeMb,
                            onUploadPressed: _pickAndUploadFile,
                            onDeleteFile: _deleteFile,
                          ),
                        ],

                        // Submit button (for draft or returned)
                        if (canEdit) ...[
                          const SizedBox(height: 24),
                          AssignmentSubmitButton(
                            isLoading: isLoading,
                            onPressed: _handleSubmit,
                          ),
                        ],

                        // Submitted banner (waiting for grade)
                        if (isSubmitted && !isGraded) ...[
                          const SizedBox(height: 24),
                          const AssignmentSubmittedBanner(),
                        ],

                        // Read-only submission view (for submitted or graded)
                        if (isReadOnly && submission != null) ...[
                          const SizedBox(height: 16),
                          _buildSubmissionCard(submission),
                        ],

                        // Submission timestamp
                        if (submission != null && submission.submittedAt != null) ...[
                          const SizedBox(height: 16),
                          _buildSubmissionInfo(submission.submittedAt!, submission.isLate),
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
                  color: const Color(0xFFFFBD59).withValues(alpha: 0.3),
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

  Widget _buildScoreCardSimple(int score) {
    final percentage = widget.totalPoints > 0
        ? (score / widget.totalPoints * 100)
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
                  '$score',
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
                  color: const Color(0xFFFFBD59).withValues(alpha: 0.3),
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
                    ? score / widget.totalPoints
                    : 0,
                minHeight: 10,
                backgroundColor: const Color(0xFFF0F0F0),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFFFFBD59)),
              ),
            ),
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

  Widget _buildSubmissionCard(submission) {
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
              'Your Submission',
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
            if (submission.textContent != null &&
                submission.textContent!.isNotEmpty) ...[
              const Text(
                'Text Content:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                submission.textContent!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2B2B2B),
                  height: 1.5,
                ),
              ),
              if (submission.files.isNotEmpty) const SizedBox(height: 16),
            ],
            if (submission.files.isNotEmpty) ...[
              const Text(
                'Files Submitted:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 8),
              ...submission.files.map(
                (file) => ListTile(
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
                ),
              ),
            ],
          ],
        ),
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
