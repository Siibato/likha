import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/services/server_clock_service.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/injection_container.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/domain/assignments/entities/submission_file.dart';
import 'package:likha/domain/assignments/usecases/create_submission.dart';
import 'package:likha/domain/assignments/usecases/upload_file.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/base_card.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/markdown_display.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/score_display_card.dart';
import 'package:likha/presentation/pages/shared/widgets/primitives/card_icon_slot.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/form_message.dart';
import 'package:likha/presentation/utils/formatters.dart';
import 'package:likha/presentation/pages/shared/widgets/dialogs/app_dialogs.dart';
import 'package:likha/presentation/pages/student/widgets/assignment_instructions_card.dart';
import 'package:likha/presentation/pages/student/widgets/assignment_returned_banner.dart';
import 'package:likha/presentation/pages/student/widgets/assignment_text_input_card.dart';
import 'package:likha/presentation/pages/student/widgets/assignment_files_card.dart';
import 'package:likha/presentation/pages/student/widgets/assignment_submit_button.dart';
import 'package:likha/presentation/pages/student/widgets/assignment_submitted_banner.dart';
import 'package:flutter/foundation.dart';
import 'package:likha/core/utils/file_opener.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';

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
  final DateTime dueAt;

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
    required this.dueAt,
  });

  @override
  ConsumerState<AssignmentDetailPage> createState() =>
      _AssignmentDetailPageState();
}

class _AssignmentDetailPageState extends ConsumerState<AssignmentDetailPage> {
  late final FleatherController _submissionController;
  String? _submissionId;
  bool _isCreatingSubmission = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _submissionController = FleatherController();
    // Always clear stale submission first, then load if submissionId exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(assignmentProvider.notifier).clearCurrentSubmission();
      if (widget.submissionId != null) {
        _submissionId = widget.submissionId;
        ref
            .read(assignmentProvider.notifier)
            .loadSubmissionDetail(widget.submissionId!);
      }
    });
  }

  @override
  void dispose() {
    _submissionController.dispose();
    super.dispose();
  }

  bool get _canSubmitText =>
      widget.submissionType == 'text' ||
      widget.submissionType == 'text_or_file';

  bool get _canSubmitFile =>
      widget.submissionType == 'file' ||
      widget.submissionType == 'text_or_file';

  String? _getTextContent() {
    if (!_canSubmitText) return null;
    final plain = _submissionController.document.toPlainText().trim();
    return plain.isEmpty ? null : jsonEncode(_submissionController.document.toJson());
  }

  Future<void> _createSubmission() async {
    setState(() => _isCreatingSubmission = true);

    await ref.read(assignmentProvider.notifier).createSubmission(
          CreateSubmissionParams(
            assignmentId: widget.assignmentId,
            textContent: _getTextContent(),
          ),
        );

    if (!mounted) return;
    final state = ref.read(assignmentProvider);
    if (state.currentSubmission != null && state.error == null) {
      setState(() {
        _submissionId = state.currentSubmission!.id;
        _isCreatingSubmission = false;
      });

      if (state.currentSubmission!.textContent != null) {
        _hydrateController(state.currentSubmission!.textContent!);
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
    if (file.path == null) {
      // Fix 4: Show error instead of silent abort when file.path is null
      setState(() => _formError = 'Could not access file. Please try again.');
      return;
    }

    if (widget.maxFileSizeMb != null) {
      final fileSizeMb = file.size / (1024 * 1024);
      if (fileSizeMb > widget.maxFileSizeMb!) {
        if (!mounted) return;
        setState(() => _formError = 'File too large. Max size is ${widget.maxFileSizeMb} MB');
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
    final effectiveStatus = ref.read(assignmentProvider).currentSubmission?.status ?? widget.submissionStatus;

    // Show confirmation dialog for re-submission
    if (effectiveStatus == 'submitted') {
      await AppDialogs.showConfirmation(
        context: context,
        title: 'Re-submit Assignment?',
        body: 'You are about to replace your existing submission. Your teacher will see the updated version.',
        confirmLabel: 'Re-submit',
        onConfirm: _performSubmit,
      );
      return;
    }

    await _performSubmit();
  }

  Future<void> _performSubmit() async {
    if (_submissionId == null) {
      await _createSubmission();
      if (_submissionId == null) return;
    }

    // If submission already exists and text has changed, persist text first
    if (_submissionId != null && _canSubmitText) {
      await _createSubmission(); // calls create_or_get which now allows submitted status
      if (!mounted) return;
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

  /// Open file — in browser on web, with system default app on native
  Future<void> _openFile(SubmissionFile file) async {
    if (kIsWeb) {
      setState(() => _formError = 'Opening file...');
      final bytes =
          await ref.read(assignmentProvider.notifier).downloadFile(file.id);
      if (!mounted) return;
      if (bytes != null) {
        await openFileInBrowser(bytes, file.fileName);
        setState(() => _formError = null);
      } else {
        setState(() => _formError = 'Failed to open file');
      }
      return;
    }

    if (file.localPath == null || file.localPath!.isEmpty) {
      if (!mounted) return;
      setState(() => _formError = 'File not cached. Downloading...');
      await _saveFile(file);
      return;
    }
    try {
      await openLocalFile(file.localPath!);
    } catch (e) {
      if (!mounted) return;
      setState(() => _formError = 'Error opening file: $e');
    }
  }

  /// Download file via provider (datasource handles caching)
  Future<void> _saveFile(SubmissionFile file) async {
    await ref.read(assignmentProvider.notifier).downloadFile(file.id);
    if (!mounted) return;
    final providerState = ref.read(assignmentProvider);
    if (providerState.error != null) {
      setState(() => _formError = 'Failed to download file');
    } else {
      setState(() => _formError = null);
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
    final rawSubmission = state.currentSubmission;
    // Guard: only use if it belongs to THIS assignment (prevents race conditions)
    final submission = (rawSubmission?.assignmentId == widget.assignmentId)
        ? rawSubmission
        : null;

    // Prefill text content if submission exists
    if (submission != null &&
        submission.textContent != null &&
        _submissionController.document.toPlainText().trim().isEmpty) {
      _hydrateController(submission.textContent!);
    }

    ref.listen<AssignmentState>(assignmentProvider, (prev, next) {
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        setState(() => _formError = null);
        ref.read(assignmentProvider.notifier).clearMessages();
        if (next.successMessage == 'Assignment submitted') {
          Navigator.pop(context, true);
        }
      }
      if (next.error != null && prev?.error != next.error) {
        setState(() => _formError = AppErrorMapper.toUserMessage(next.error));
        ref.read(assignmentProvider.notifier).clearMessages();
      }
    });

    // Use submission status from loaded data, or fall back to initial status from widget
    final effectiveStatus = submission?.status ?? widget.submissionStatus;
    final isGraded = effectiveStatus == 'graded';
    final isSubmitted = effectiveStatus == 'submitted';
    final isDeadlinePassed = sl<ServerClockService>().now().isAfter(widget.dueAt);
    final canEditSubmitted = isSubmitted && !isDeadlinePassed; // submitted but editable
    final canEdit = !isGraded && (!isSubmitted || canEditSubmitted);
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
                  const SliverToBoxAdapter(
                    child: ClassSectionHeader(
                      title: 'Assignment Details',
                      showBackButton: true,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Form Error Display
                        FormMessage(
                          message: _formError,
                          severity: MessageSeverity.error,
                        ),
                        if (_formError != null) const SizedBox(height: 12),

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
                            ScoreDisplayCard(
                              score: submission.score!,
                              totalPoints: widget.totalPoints ?? 0,
                              useBaseCardStyle: true,
                              gradedAt: submission.gradedAt,
                              formatDateTime: (dt) => formatDateTimeDisplay(dt),
                            )
                          else if (widget.score != null)
                            ScoreDisplayCard(
                              score: widget.score!,
                              totalPoints: widget.totalPoints ?? 0,
                              useBaseCardStyle: true,
                            ),
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
                            controller: _submissionController,
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

                        // Submit button (for draft, returned, or editable submitted)
                        if (canEdit) ...[
                          const SizedBox(height: 24),
                          AssignmentSubmitButton(
                            isLoading: isLoading,
                            onPressed: _handleSubmit,
                            text: canEditSubmitted ? 'Re-submit Assignment' : 'Submit Assignment',
                          ),
                        ],

                        // Submitted banner (waiting for grade)
                        if (isSubmitted && !isGraded) ...[
                          const SizedBox(height: 24),
                          const AssignmentSubmittedBanner(),
                        ],

                        // Read-only submission view (for graded or submitted after deadline)
                        if (!canEdit && submission != null) ...[
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

  void _hydrateController(String content) {
    if (content.isEmpty) return;
    try {
      final doc = ParchmentDocument.fromJson(jsonDecode(content));
      setState(() => _submissionController = FleatherController(document: doc));
    } catch (_) {
      // Fallback: leave as empty or could insert as plain text if needed
    }
  }

  Widget _buildFeedbackCard(String feedback) {
    return BaseCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
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
    );
  }

  Widget _buildSubmissionCard(AssignmentSubmission submission) {
    return BaseCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
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
            MarkdownDisplay(content: submission.textContent),
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
                leading: CardIconSlot.sm(
                  icon: Icons.attach_file_rounded,
                  iconColor: AppColors.foregroundSecondary,
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
                  icon: kIsWeb
                      ? const Icon(Icons.open_in_browser_rounded, color: Color(0xFF2B2B2B))
                      : file.isCached
                          ? const Icon(Icons.folder_open_rounded)
                          : const Icon(Icons.download_rounded, color: Color(0xFF2B2B2B)),
                  onPressed: () => kIsWeb
                      ? _openFile(file)
                      : file.isCached
                          ? _openFile(file)
                          : _saveFile(file),
                ),
              ),
            ),
          ],
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
