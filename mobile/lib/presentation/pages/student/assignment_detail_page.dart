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
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';
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
import 'package:likha/core/logging/page_logger.dart';

class AssignmentDetailPage extends ConsumerStatefulWidget {
  final String assignmentId;
  final String assignmentTitle;
  final String instructions;
  final bool allowsTextSubmission;
  final bool allowsFileSubmission;
  final int totalPoints;
  final String? allowedFileTypes;
  final int? maxFileSizeMb;
  final String? submissionId;
  final int? score;
  final String? submissionStatus;
  final DateTime dueAt;
  final bool isNewAttempt;

  const AssignmentDetailPage({
    super.key,
    required this.assignmentId,
    required this.assignmentTitle,
    required this.instructions,
    required this.allowsTextSubmission,
    required this.allowsFileSubmission,
    required this.totalPoints,
    this.allowedFileTypes,
    this.maxFileSizeMb,
    this.submissionId,
    this.score,
    this.submissionStatus,
    required this.dueAt,
    this.isNewAttempt = false,
  });

  @override
  ConsumerState<AssignmentDetailPage> createState() =>
      _AssignmentDetailPageState();
}

class _AssignmentDetailPageState extends ConsumerState<AssignmentDetailPage> {
  late FleatherController _submissionController;
  String? _submissionId;
  bool _isCreatingSubmission = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _submissionController = FleatherController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(assignmentProvider.notifier).clearCurrentSubmission();
      // In new-attempt mode we never load the old submission — fresh editor only.
      // In view mode we load the existing submission to display it.
      if (!widget.isNewAttempt && widget.submissionId != null) {
        _submissionId = widget.submissionId;
        _loadSubmissionWithOfflineSupport(widget.submissionId!);
      }
    });
  }

  /// Load submission with offline-first support
  /// Attempts to load submission details and handles offline scenarios gracefully
  Future<void> _loadSubmissionWithOfflineSupport(String submissionId) async {
    await ref.read(assignmentProvider.notifier).loadSubmissionDetail(submissionId);
    
    // If loading failed and we have a submitted status, this might be an offline submission
    // Give it a moment to settle and check if we have cached data
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
      final state = ref.read(assignmentProvider);
      if (state.currentSubmission == null && widget.submissionStatus == 'submitted') {
        // This is likely an offline submission that hasn't been fully processed yet
        // The submission exists but couldn't be loaded due to network issues
        // We'll handle this in the UI state management
      }
    }
  }

  /// Load text content from local cache for offline submissions
  /// This method attempts to retrieve the text content directly from the local database
  /// when the full submission object couldn't be loaded due to network issues
  Future<void> _loadOfflineSubmissionText(String submissionId) async {
    try {
      // Access the local data source directly to get cached submission text
      final assignmentRepo = sl<AssignmentRepository>();
      final result = await assignmentRepo.getSubmissionDetail(submissionId: submissionId);
      
      result.fold(
        (failure) {
          // If even the cache fails, we can't do much - this is expected for very recent submissions
          // that haven't been cached yet
        },
        (submission) {
          if (submission.textContent != null && mounted) {
            _hydrateController(submission.textContent!);
          }
        },
      );
    } catch (e) {
      // Silently fail - this is a best-effort attempt to show cached content
    }
  }

  @override
  void dispose() {
    _submissionController.dispose();
    super.dispose();
  }

  bool get _canSubmitText => widget.allowsTextSubmission;

  bool get _canSubmitFile => widget.allowsFileSubmission;

  String? _getTextContent() {
    if (!_canSubmitText) return null;
    final plain = _submissionController.document.toPlainText().trim();
    return plain.isEmpty ? null : jsonEncode(_submissionController.document.toJson());
  }

  Future<void> _createSubmission() async {
    PageLogger.instance.warn('[CREATE] _createSubmission START — assignmentId=${widget.assignmentId} text=${_getTextContent()?.substring(0, (_getTextContent()?.length ?? 0).clamp(0, 40))}');
    setState(() => _isCreatingSubmission = true);

    await ref.read(assignmentProvider.notifier).createSubmission(
          CreateSubmissionParams(
            assignmentId: widget.assignmentId,
            textContent: _getTextContent(),
          ),
        );

    if (!mounted) return;
    final state = ref.read(assignmentProvider);
    PageLogger.instance.warn('[CREATE] after createSubmission — currentSubmission=${state.currentSubmission?.id} needsSync=${state.currentSubmission?.needsSync} error=${state.error}');
    if (state.currentSubmission != null && state.error == null) {
      setState(() {
        _submissionId = state.currentSubmission!.id;
        _isCreatingSubmission = false;
      });

      if (state.currentSubmission!.textContent != null) {
        _hydrateController(state.currentSubmission!.textContent!);
      }
    } else {
      PageLogger.instance.warn('[CREATE] createSubmission had no submission or had error — error=${state.error}');
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
    await _performSubmit();
  }

  Future<void> _performSubmit() async {
    PageLogger.instance.warn('[SUBMIT] _performSubmit START — submissionId=$_submissionId isNewAttempt=${widget.isNewAttempt}');
    if (_submissionId == null) {
      PageLogger.instance.warn('[SUBMIT] no submissionId, calling _createSubmission');
      await _createSubmission();
      PageLogger.instance.warn('[SUBMIT] after _createSubmission — submissionId=$_submissionId');
      if (_submissionId == null) {
        PageLogger.instance.warn('[SUBMIT] _createSubmission failed, aborting');
        return;
      }
    }

    if (!mounted) return;

    PageLogger.instance.warn('[SUBMIT] calling submitAssignment($_submissionId)');
    await ref
        .read(assignmentProvider.notifier)
        .submitAssignment(_submissionId!);
    PageLogger.instance.warn('[SUBMIT] submitAssignment returned');
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

  Future<bool> _confirmDiscard() async {
    final hasText = _submissionController.document.toPlainText().trim().isNotEmpty;
    final hasFiles = ref.read(assignmentProvider).currentSubmission?.files.isNotEmpty ?? false;
    if (!hasText && !hasFiles) return true;
    bool shouldDiscard = false;
    await AppDialogs.showConfirmation(
      context: context,
      title: 'Discard new attempt?',
      body: 'Your changes will not be saved.',
      confirmLabel: 'Discard',
      onConfirm: () => shouldDiscard = true,
    );
    return shouldDiscard;
  }

  void _openNewAttempt() {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AssignmentDetailPage(
          assignmentId: widget.assignmentId,
          assignmentTitle: widget.assignmentTitle,
          instructions: widget.instructions,
          allowsTextSubmission: widget.allowsTextSubmission,
          allowsFileSubmission: widget.allowsFileSubmission,
          totalPoints: widget.totalPoints,
          allowedFileTypes: widget.allowedFileTypes,
          maxFileSizeMb: widget.maxFileSizeMb,
          submissionId: null,
          score: null,
          submissionStatus: null,
          dueAt: widget.dueAt,
          isNewAttempt: true,
        ),
      ),
    ).then((submitted) {
      if (submitted == true && mounted) {
        Navigator.pop(context, true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assignmentProvider);
    final rawSubmission = state.currentSubmission;
    // Guard: only use if it belongs to THIS assignment (prevents race conditions)
    // In new-attempt mode there is no prior submission to display.
    final submission = (!widget.isNewAttempt && rawSubmission?.assignmentId == widget.assignmentId)
        ? rawSubmission
        : null;

    // Prefill text content if submission exists (view/graded/returned modes only)
    if (!widget.isNewAttempt &&
        submission != null &&
        submission.textContent != null &&
        _submissionController.document.toPlainText().trim().isEmpty) {
      _hydrateController(submission.textContent!);
    }

    // For offline submissions: if submission is null but we have a submitted status,
    // try to load the text content from local cache
    if (!widget.isNewAttempt &&
        submission == null &&
        widget.submissionStatus == 'submitted' &&
        widget.submissionId != null &&
        _submissionController.document.toPlainText().trim().isEmpty) {
      _loadOfflineSubmissionText(widget.submissionId!);
    }

    ref.listen<AssignmentState>(assignmentProvider, (prev, next) {
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        PageLogger.instance.warn('[LISTEN] successMessage=${next.successMessage} needsSync=${next.currentSubmission?.needsSync}');
        setState(() => _formError = null);
        ref.read(assignmentProvider.notifier).clearMessages();
        if (next.successMessage == 'Assignment submitted') {
          final isOffline = next.currentSubmission?.needsSync == true;
          PageLogger.instance.warn('[LISTEN] Assignment submitted — isOffline=$isOffline, popping');
          if (isOffline && mounted) {
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
        PageLogger.instance.warn('[LISTEN] error=${next.error} isNewAttempt=${widget.isNewAttempt} submissionStatus=${widget.submissionStatus}');
        // Only show errors on editable pages (draft / returned / no prior submission).
        // View-mode pages (submitted) and new-attempt pages must not surface errors
        // from sibling/child pages sharing the same provider.
        final isEditablePage = !widget.isNewAttempt &&
            widget.submissionStatus != 'submitted' &&
            widget.submissionStatus != 'graded';
        if (isEditablePage) {
          final errorMessage = AppErrorMapper.toUserMessage(next.error);
          setState(() => _formError = errorMessage);
        }
        ref.read(assignmentProvider.notifier).clearMessages();
      }
    });

    final effectiveStatus = submission?.status ?? widget.submissionStatus;
    final isGraded = effectiveStatus == 'graded';
    final isSubmitted = effectiveStatus == 'submitted';
    final isOfflineSubmitted = !widget.isNewAttempt && widget.submissionStatus == 'submitted' && submission == null;
    final isDeadlinePassed = sl<ServerClockService>().now().isAfter(widget.dueAt);

    // VIEW MODE: student already submitted — show read-only content, not an editor.
    // NEW ATTEMPT MODE: blank editor for creating a fresh submission.
    // EDIT MODE: draft / returned — editable as before.
    final isViewMode = !widget.isNewAttempt && (isSubmitted || isOfflineSubmitted) && !isGraded;
    final isReturnedEdit = effectiveStatus == 'returned';
    final canEdit = widget.isNewAttempt || (!isGraded && !isViewMode && (effectiveStatus == null || effectiveStatus == 'draft' || isReturnedEdit));
    final isLoading = (state.isLoading || _isCreatingSubmission) && !isOfflineSubmitted;

    final pageTitle = widget.isNewAttempt ? 'New Attempt' : 'Assignment Details';

    return PopScope(
      canPop: !widget.isNewAttempt,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        final ok = await _confirmDiscard();
        if (ok) nav.pop(false);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: SafeArea(
          child: state.isLoading && submission == null && !isOfflineSubmitted && !widget.isNewAttempt
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
                        title: pageTitle,
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

                          // Graded view — show score first
                          if (isGraded) ...[
                            const SizedBox(height: 16),
                            if (submission != null && submission.score != null)
                              ScoreDisplayCard(
                                score: submission.score!,
                                totalPoints: widget.totalPoints,
                                useBaseCardStyle: true,
                                gradedAt: submission.gradedAt,
                                formatDateTime: (dt) => formatDateTimeDisplay(dt),
                              )
                            else if (widget.score != null)
                              ScoreDisplayCard(
                                score: widget.score!,
                                totalPoints: widget.totalPoints,
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

                          // ── VIEW MODE (submitted, not graded) ──────────────────────
                          if (isViewMode) ...[
                            // Submitted banner
                            const SizedBox(height: 24),
                            const AssignmentSubmittedBanner(),

                            // Read-only submission content
                            if (submission != null) ...[
                              const SizedBox(height: 16),
                              _buildSubmissionCard(submission),
                            ],

                            // Submission timestamp
                            if (submission != null && submission.submittedAt != null) ...[
                              const SizedBox(height: 16),
                              _buildSubmissionInfo(submission.submittedAt!),
                            ],

                            // Create new attempt button (only before deadline)
                            if (!isDeadlinePassed) ...[
                              const SizedBox(height: 24),
                              _buildNewAttemptButton(),
                            ],
                          ],

                          // ── EDITOR MODE (new attempt / draft / returned) ───────────
                          if (canEdit) ...[
                            if (_canSubmitText) ...[
                              const SizedBox(height: 16),
                              AssignmentTextInputCard(
                                controller: _submissionController,
                                isReadOnly: false,
                              ),
                            ],
                            if (_canSubmitFile) ...[
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
                            const SizedBox(height: 24),
                            AssignmentSubmitButton(
                              isLoading: isLoading,
                              onPressed: _handleSubmit,
                              text: isReturnedEdit ? 'Re-submit Assignment' : 'Submit Assignment',
                            ),
                          ],

                          // ── GRADED: read-only submission card ──────────────────────
                          if (isGraded && submission != null) ...[
                            const SizedBox(height: 16),
                            _buildSubmissionCard(submission),
                            if (submission.submittedAt != null) ...[
                              const SizedBox(height: 16),
                              _buildSubmissionInfo(submission.submittedAt!),
                            ],
                          ],

                          const SizedBox(height: 40),
                        ]),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildNewAttemptButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _openNewAttempt,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: const BorderSide(color: Color(0xFF2B2B2B), width: 1.5),
          foregroundColor: const Color(0xFF2B2B2B),
        ),
        child: const Text(
          'Create New Attempt',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
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

  
  Widget _buildSubmissionInfo(DateTime submittedAt) {
    return Center(
      child: Text(
        'Submitted: ${_formatDateTime(submittedAt)}',
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
