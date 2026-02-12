import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/domain/assignments/usecases/create_submission.dart';
import 'package:likha/domain/assignments/usecases/upload_file.dart';
import 'package:likha/presentation/pages/student/widgets/student_header.dart';
import 'package:likha/presentation/pages/student/widgets/assignment_instructions_card.dart';
import 'package:likha/presentation/pages/student/widgets/assignment_returned_banner.dart';
import 'package:likha/presentation/pages/student/widgets/assignment_text_input_card.dart';
import 'package:likha/presentation/pages/student/widgets/assignment_files_card.dart';
import 'package:likha/presentation/pages/student/widgets/assignment_submit_button.dart';
import 'package:likha/presentation/pages/student/widgets/assignment_submitted_banner.dart';
import 'package:likha/presentation/pages/student/widgets/assignment_graded_banner.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';

class SubmitAssignmentPage extends ConsumerStatefulWidget {
  final String assignmentId;
  final String assignmentTitle;
  final String instructions;
  final String submissionType;
  final int totalPoints;
  final String? allowedFileTypes;
  final int? maxFileSizeMb;

  const SubmitAssignmentPage({
    super.key,
    required this.assignmentId,
    required this.assignmentTitle,
    required this.instructions,
    required this.submissionType,
    required this.totalPoints,
    this.allowedFileTypes,
    this.maxFileSizeMb,
  });

  @override
  ConsumerState<SubmitAssignmentPage> createState() =>
      _SubmitAssignmentPageState();
}

class _SubmitAssignmentPageState extends ConsumerState<SubmitAssignmentPage> {
  final _textController = TextEditingController();
  String? _submissionId;
  bool _isCreatingSubmission = false;

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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assignmentProvider);
    final submission = state.currentSubmission;

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

    final isSubmitted = submission != null && submission.status == 'submitted';
    final isGraded = submission != null && submission.status == 'graded';
    final isReadOnly = isSubmitted || isGraded;
    final isLoading = state.isLoading || _isCreatingSubmission;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: StudentHeader(
                title: widget.assignmentTitle,
                showBackButton: true,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  AssignmentInstructionsCard(
                    instructions: widget.instructions,
                    totalPoints: widget.totalPoints,
                  ),
                  if (submission != null &&
                      submission.status == 'returned' &&
                      submission.feedback != null) ...[
                    const SizedBox(height: 16),
                    AssignmentReturnedBanner(feedback: submission.feedback!),
                  ],
                  if (isGraded && submission.score != null) ...[
                    const SizedBox(height: 16),
                    AssignmentGradedBanner(
                      score: submission.score!,
                      totalPoints: widget.totalPoints,
                      feedback: submission.feedback,
                    ),
                  ],
                  if (_canSubmitText) ...[
                    const SizedBox(height: 16),
                    AssignmentTextInputCard(
                      controller: _textController,
                      isReadOnly: isReadOnly,
                    ),
                  ],
                  if (_canSubmitFile) ...[
                    const SizedBox(height: 16),
                    AssignmentFilesCard(
                      files: submission?.files ?? [],
                      isReadOnly: isReadOnly,
                      allowedFileTypes: widget.allowedFileTypes,
                      maxFileSizeMb: widget.maxFileSizeMb,
                      onUploadPressed: _pickAndUploadFile,
                      onDeleteFile: _deleteFile,
                    ),
                  ],
                  if (!isReadOnly) ...[
                    const SizedBox(height: 24),
                    AssignmentSubmitButton(
                      isLoading: isLoading,
                      onPressed: _handleSubmit,
                    ),
                  ],
                  if (isSubmitted && !isGraded) ...[
                    const SizedBox(height: 16),
                    const AssignmentSubmittedBanner(),
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
}