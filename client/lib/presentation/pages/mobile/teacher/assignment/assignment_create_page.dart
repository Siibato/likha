import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/controllers/teacher/assignment/assignment_create_controller.dart';
import 'package:likha/presentation/providers/assignment/assignment_list_provider.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assignment/assignment_grade_settings.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assignment/assignment_instructions_field.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assignment/assignment_points_field.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assignment/assignment_publish_settings.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assignment/assignment_submission_options.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assignment/assignment_title_field.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assignment/assignment_save_button.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assignment/file_type_picker_sheet.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assignment/shared_due_date_time_picker.dart';
import 'package:likha/presentation/widgets/shared/feedback/provider_message_listener.dart';
import 'package:likha/presentation/widgets/shared/forms/form_message.dart';

class CreateAssignmentPage extends ConsumerStatefulWidget {
  final String classId;

  const CreateAssignmentPage({super.key, required this.classId});

  @override
  ConsumerState<CreateAssignmentPage> createState() =>
      _CreateAssignmentPageState();
}

class _CreateAssignmentPageState extends ConsumerState<CreateAssignmentPage> {
  final _formKey = GlobalKey<FormState>();
  late final AssignmentCreateController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AssignmentCreateController(
      classId: widget.classId,
      notifier: ref.read(assignmentListProvider.notifier),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showFileTypesPicker() async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) =>
          FileTypePickerSheet(initialSelection: _controller.selectedFileTypes),
    );
    if (result != null) _controller.setSelectedFileTypes(result);
  }

  @override
  Widget build(BuildContext context) {
    return ProviderMessageListener<AssignmentListState>(
      provider: assignmentListProvider,
      successMessage: (s) => s.successMessage,
      errorMessage: (s) => s.error,
      onClear: () => ref.read(assignmentListProvider.notifier).clearMessages(),
      intercept: (prev, next) {
        if (next.successMessage == 'Assignment created') {
          Navigator.pop(context, true);
          return true;
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundSecondary,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.accentCharcoal),
          title: const Text(
            'Create Assignment',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.accentCharcoal,
              letterSpacing: -0.4,
            ),
          ),
        ),
        body: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FormMessage(
                      message: _controller.formError,
                      severity: MessageSeverity.error,
                    ),
                    const SizedBox(height: 16),
                    AssignmentTitleField(
                      controller: _controller.titleController,
                      enabled: !_controller.isSaving,
                      onChanged: (_) => _controller.clearFormError(),
                    ),
                    const SizedBox(height: 16),
                    AssignmentInstructionsField(
                      controller: _controller.instructionsController,
                      enabled: !_controller.isSaving,
                    ),
                    const SizedBox(height: 16),
                    AssignmentPointsField(
                      controller: _controller.totalPointsController,
                      enabled: !_controller.isSaving,
                    ),
                    const SizedBox(height: 16),
                    AssignmentSubmissionOptions(
                      allowsTextSubmission: _controller.allowsTextSubmission,
                      allowsFileSubmission: _controller.allowsFileSubmission,
                      selectedFileTypes: _controller.selectedFileTypes,
                      maxFileSizeController: _controller.maxFileSizeController,
                      enabled: !_controller.isSaving,
                      onTextToggle: _controller.setAllowsTextSubmission,
                      onFileToggle: _controller.setAllowsFileSubmission,
                      onPickFileTypes: _showFileTypesPicker,
                    ),
                    const SizedBox(height: 16),
                    SharedDueDateTimePicker(
                      label: 'Due Date',
                      dateTime: _controller.dueAt,
                      icon: Icons.event_rounded,
                      enabled: !_controller.isSaving,
                      onChanged: _controller.setDueAt,
                    ),
                    const SizedBox(height: 16),
                    AssignmentGradeSettings(
                      termNumber: _controller.termNumber,
                      component: _controller.component,
                      enabled: !_controller.isSaving,
                      onTermChanged: _controller.setTermNumber,
                      onComponentChanged: _controller.setComponent,
                    ),
                    const SizedBox(height: 8),
                    AssignmentPublishSettings(
                      noSubmissionRequired: _controller.noSubmissionRequired,
                      isPublished: _controller.isPublished,
                      enabled: !_controller.isSaving,
                      onNoSubmissionChanged:
                          _controller.setNoSubmissionRequired,
                      onPublishChanged: _controller.setIsPublished,
                    ),
                    const SizedBox(height: 32),
                    AssignmentSaveButton(
                      isSaving: _controller.isSaving,
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        final success = await _controller.performSave();
                        if (success && context.mounted) {
                          Navigator.pop(context, true);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
