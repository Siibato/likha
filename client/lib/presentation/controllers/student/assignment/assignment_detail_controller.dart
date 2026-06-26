import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/logging/page_logger.dart';
import 'package:likha/domain/assignments/entities/submission_file.dart';
import 'package:likha/domain/assignments/usecases/create_submission.dart';
import 'package:likha/domain/assignments/usecases/upload_file.dart';
import 'package:likha/presentation/providers/assignment/file_upload_provider.dart';
import 'package:likha/presentation/providers/assignment/submission_provider.dart';

/// Controller for the student assignment detail/submission flow.
///
/// Owns the Fleather text editor, file upload orchestration, submission
/// creation, and form error state. Consumed by the mobile assignment
/// detail page via [ListenableBuilder].
class AssignmentDetailController extends ChangeNotifier {
  final String assignmentId;
  final bool allowsTextSubmission;
  final bool allowsFileSubmission;
  final String? allowedFileTypes;
  final int? maxFileSizeMb;
  final String? initialSubmissionId;
  final String? initialSubmissionStatus;
  final bool isNewAttempt;
  final SubmissionNotifier notifier;
  final FileUploadNotifier fileUploadNotifier;

  late FleatherController submissionController;
  String? _submissionId;
  bool _isCreatingSubmission = false;
  String? formError;

  AssignmentDetailController({
    required this.assignmentId,
    required this.allowsTextSubmission,
    required this.allowsFileSubmission,
    this.allowedFileTypes,
    this.maxFileSizeMb,
    this.initialSubmissionId,
    this.initialSubmissionStatus,
    this.isNewAttempt = false,
    required this.notifier,
    required this.fileUploadNotifier,
  }) {
    submissionController = FleatherController();
  }

  String? get submissionId => _submissionId;
  bool get isCreatingSubmission => _isCreatingSubmission;
  bool get canSubmitText => allowsTextSubmission;
  bool get canSubmitFile => allowsFileSubmission;

  void init() {
    notifier.clearCurrentSubmission();
    if (!isNewAttempt && initialSubmissionId != null) {
      _submissionId = initialSubmissionId;
      loadOfflineSubmissionText(initialSubmissionId!);
    }
  }

  @override
  void dispose() {
    submissionController.dispose();
    super.dispose();
  }

  Future<void> loadOfflineSubmissionText(String submissionId) async {
    await notifier.loadSubmissionDetail(submissionId);
    if (_hasSubmissionText) {
      hydrateController(notifier.currentState.currentSubmission?.textContent);
    }
  }

  bool get _hasSubmissionText {
    return notifier.currentState.currentSubmission?.textContent != null;
  }

  String? getTextContent() {
    if (!canSubmitText) return null;
    final plain = submissionController.document.toPlainText().trim();
    return plain.isEmpty ? null : jsonEncode(submissionController.document.toJson());
  }

  Future<void> createSubmission() async {
    PageLogger.instance.warn(
        '[CREATE] _createSubmission START — assignmentId=$assignmentId text=${getTextContent()?.substring(0, (getTextContent()?.length ?? 0).clamp(0, 40))}');
    _isCreatingSubmission = true;
    notifyListeners();

    await notifier.createSubmission(
      CreateSubmissionParams(
        assignmentId: assignmentId,
        textContent: getTextContent(),
      ),
    );

    final state = notifier.currentState;
    PageLogger.instance.warn(
        '[CREATE] after createSubmission — currentSubmission=${state.currentSubmission?.id} syncStatus=${state.currentSubmission?.syncStatus} error=${state.error}');
    if (state.currentSubmission != null && state.error == null) {
      _submissionId = state.currentSubmission!.id;
      _isCreatingSubmission = false;
      if (state.currentSubmission!.textContent != null) {
        hydrateController(state.currentSubmission!.textContent!);
      }
    } else {
      PageLogger.instance.warn(
          '[CREATE] createSubmission had no submission or had error — error=${state.error}');
      _isCreatingSubmission = false;
    }
    notifyListeners();
  }

  Future<void> pickAndUploadFile() async {
    if (_submissionId == null) {
      await createSubmission();
      if (_submissionId == null) return;
    }

    List<String>? allowedExtensions;
    if (allowedFileTypes != null && allowedFileTypes!.isNotEmpty) {
      allowedExtensions =
          allowedFileTypes!.split(',').map((e) => e.trim()).toList();
    }

    final result = await FilePicker.platform.pickFiles(
      type: allowedExtensions != null ? FileType.custom : FileType.any,
      allowedExtensions: allowedExtensions,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) {
      formError = 'Could not access file. Please try again.';
      notifyListeners();
      return;
    }

    if (maxFileSizeMb != null) {
      final fileSizeMb = file.size / (1024 * 1024);
      if (fileSizeMb > maxFileSizeMb!) {
        formError = 'File too large. Max size is $maxFileSizeMb MB';
        notifyListeners();
        return;
      }
    }

    final uploadError = await fileUploadNotifier.uploadFile(
      UploadFileParams(
        submissionId: _submissionId!,
        filePath: file.path!,
        fileName: file.name,
      ),
    );

    formError = uploadError != null
        ? AppErrorMapper.toUserMessage(uploadError)
        : null;
    notifyListeners();
  }

  Future<void> performSubmit() async {
    PageLogger.instance.warn(
        '[SUBMIT] _performSubmit START — submissionId=$_submissionId isNewAttempt=$isNewAttempt');
    await createSubmission();
    PageLogger.instance.warn('[SUBMIT] after _createSubmission — submissionId=$_submissionId');
    if (_submissionId == null) {
      PageLogger.instance.warn('[SUBMIT] _createSubmission failed, aborting');
      return;
    }

    PageLogger.instance.warn('[SUBMIT] calling submitAssignment($_submissionId)');
    await notifier.submitAssignment(_submissionId!);
    PageLogger.instance.warn('[SUBMIT] submitAssignment returned');
  }

  Future<void> deleteFile(String fileId) async {
    await notifier.deleteSubmissionFile(fileId);
  }

  Future<void> openFile(SubmissionFile file) async {
    // Web is handled in the page because it needs context for snackbars
    if (file.localPath == null || file.localPath!.isEmpty) {
      formError = 'File not cached. Downloading...';
      notifyListeners();
      await saveFile(file);
      return;
    }
    // Page handles the actual open via core/utils/file_opener
  }

  Future<void> saveFile(SubmissionFile file) async {
    final bytes = await fileUploadNotifier.downloadFile(file.id);
    formError = bytes == null ? 'Failed to download file' : null;
    notifyListeners();
  }

  bool get hasUnsavedContent {
    final hasText = submissionController.document.toPlainText().trim().isNotEmpty;
    final hasFiles = notifier.currentState.currentSubmission?.files.isNotEmpty ?? false;
    return hasText || hasFiles;
  }

  void clearFormError() {
    if (formError != null) {
      formError = null;
      notifyListeners();
    }
  }

  void setFormError(String? error) {
    if (formError != error) {
      formError = error;
      notifyListeners();
    }
  }

  void hydrateController(String? content) {
    if (content == null || content.isEmpty) return;
    try {
      final doc = ParchmentDocument.fromJson(jsonDecode(content));
      submissionController = FleatherController(document: doc);
      notifyListeners();
    } catch (_) {
      // Fallback: leave as empty
    }
  }
}
