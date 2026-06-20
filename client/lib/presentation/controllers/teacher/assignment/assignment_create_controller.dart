import 'dart:convert';

import 'package:fleather/fleather.dart';
import 'package:flutter/widgets.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/utils/formatters.dart';
import 'package:likha/domain/assignments/usecases/create_assignment.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';

/// Controller for the assignment creation flow.
///
/// Owns all mutable form state, validation, and save orchestration.
/// Both mobile and desktop pages consume this via [ListenableBuilder].
class AssignmentCreateController extends ChangeNotifier {
  final String classId;
  final AssignmentNotifier notifier;

  final titleController = TextEditingController();
  late final FleatherController instructionsController;
  final totalPointsController = TextEditingController(text: '100');
  final maxFileSizeController = TextEditingController(text: '10');

  Set<String> selectedFileTypes = {};
  bool allowsTextSubmission = true;
  bool allowsFileSubmission = false;
  DateTime dueAt = DateTime.now().add(const Duration(days: 7));
  bool isPublished = true;
  int? termNumber;
  String? component = 'pt';
  bool noSubmissionRequired = false;
  bool isSaving = false;
  String? formError;

  AssignmentCreateController({
    required this.classId,
    required this.notifier,
  }) {
    instructionsController = FleatherController();
  }

  @override
  void dispose() {
    titleController.dispose();
    instructionsController.dispose();
    totalPointsController.dispose();
    maxFileSizeController.dispose();
    super.dispose();
  }

  void setAllowsTextSubmission(bool value) {
    allowsTextSubmission = value;
    formError = null;
    notifyListeners();
  }

  void setAllowsFileSubmission(bool value) {
    allowsFileSubmission = value;
    formError = null;
    notifyListeners();
  }

  void setSelectedFileTypes(Set<String> value) {
    selectedFileTypes = value;
    formError = null;
    notifyListeners();
  }

  void setDueAt(DateTime value) {
    dueAt = value;
    formError = null;
    notifyListeners();
  }

  void setIsPublished(bool value) {
    isPublished = value;
    formError = null;
    notifyListeners();
  }

  void setTermNumber(int? value) {
    termNumber = value;
    formError = null;
    notifyListeners();
  }

  void setComponent(String? value) {
    component = value;
    formError = null;
    notifyListeners();
  }

  void setNoSubmissionRequired(bool value) {
    noSubmissionRequired = value;
    formError = null;
    notifyListeners();
  }

  void clearFormError() {
    if (formError != null) {
      formError = null;
      notifyListeners();
    }
  }

  String? _validate() {
    if (titleController.text.trim().isEmpty) {
      return 'Title is required';
    }

    final totalPoints = int.tryParse(totalPointsController.text.trim());
    if (totalPoints == null || totalPoints <= 0 || totalPoints > 1000) {
      return 'Total points must be between 1 and 1000';
    }

    return null;
  }

  Future<bool> performSave() async {
    final error = _validate();
    if (error != null) {
      formError = error;
      notifyListeners();
      return false;
    }

    isSaving = true;
    formError = null;
    notifyListeners();

    String? allowedFileTypes;
    int? maxFileSizeMb;
    if (allowsFileSubmission) {
      if (selectedFileTypes.isNotEmpty) {
        allowedFileTypes = selectedFileTypes.join(',');
      }
      final maxSize = int.tryParse(maxFileSizeController.text.trim());
      if (maxSize != null && maxSize > 0) maxFileSizeMb = maxSize;
    }

    await notifier.createAssignment(
      CreateAssignmentParams(
        classId: classId,
        title: titleController.text.trim(),
        instructions: jsonEncode(instructionsController.document.toJson()),
        totalPoints: int.parse(totalPointsController.text.trim()),
        allowsTextSubmission: allowsTextSubmission,
        allowsFileSubmission: allowsFileSubmission,
        allowedFileTypes: allowedFileTypes,
        maxFileSizeMb: maxFileSizeMb,
        dueAt: formatDateTimeForApi(dueAt),
        isPublished: isPublished,
        termNumber: termNumber,
        component: component,
        noSubmissionRequired: noSubmissionRequired,
      ),
    );

    isSaving = false;

    if (notifier.currentError != null) {
      formError = AppErrorMapper.toUserMessage(notifier.currentError);
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }
}
