import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/controllers/teacher/assignment/assignment_create_controller.dart';
import 'package:likha/presentation/layouts/desktop/desktop_page_scaffold.dart';
import 'package:likha/presentation/providers/assignment/assignment_list_provider.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assignment/assignment_create_form.dart';
import 'package:likha/presentation/widgets/shared/feedback/provider_message_listener.dart';

class CreateAssignmentPage extends ConsumerStatefulWidget {
  final String classId;

  const CreateAssignmentPage({super.key, required this.classId});

  @override
  ConsumerState<CreateAssignmentPage> createState() =>
      _CreateAssignmentPageState();
}

class _CreateAssignmentPageState
    extends ConsumerState<CreateAssignmentPage> {
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

  String _submissionTypeFromBools(bool text, bool file) {
    if (text && file) return 'text_or_file';
    if (text) return 'text';
    if (file) return 'file';
    return 'text_or_file';
  }

  void _onSubmissionTypeChanged(String value) {
    switch (value) {
      case 'text_or_file':
        _controller.setAllowsTextSubmission(true);
        _controller.setAllowsFileSubmission(true);
        break;
      case 'text':
        _controller.setAllowsTextSubmission(true);
        _controller.setAllowsFileSubmission(false);
        break;
      case 'file':
        _controller.setAllowsTextSubmission(false);
        _controller.setAllowsFileSubmission(true);
        break;
    }
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _controller.dueAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.accentCharcoal,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: AppColors.accentCharcoal,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_controller.dueAt),
      initialEntryMode: TimePickerEntryMode.input,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.accentCharcoal,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: AppColors.accentCharcoal,
            secondary: AppColors.accentCharcoal,
            tertiary: AppColors.accentCharcoal,
            onTertiary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    _controller.setDueAt(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProviderMessageListener<AssignmentListState>(
      provider: assignmentListProvider,
      successMessage: (s) => s.successMessage,
      errorMessage: (s) => s.error,
      onClear: () => ref.read(assignmentListProvider.notifier).clearMessages(),
      intercept: (prev, next) {
        if (next.successMessage == 'Assignment created' &&
            prev.successMessage != 'Assignment created') {
          Navigator.pop(context, true);
          return true;
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundSecondary,
        body: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            return DesktopPageScaffold(
              title: 'Create Assignment',
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Back',
              ),
              body: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: AssignmentCreateForm(
                    formKey: _formKey,
                    titleController: _controller.titleController,
                    instructionsController: _controller.instructionsController,
                    totalPointsController: _controller.totalPointsController,
                    submissionType: _submissionTypeFromBools(
                      _controller.allowsTextSubmission,
                      _controller.allowsFileSubmission,
                    ),
                    dueAt: _controller.dueAt,
                    termNumber: _controller.termNumber,
                    component: _controller.component,
                    isPublished: _controller.isPublished,
                    formError: _controller.formError,
                    isSaving: _controller.isSaving,
                    onSave: () async {
                      if (!_formKey.currentState!.validate()) return;
                      await _controller.performSave();
                    },
                    onSubmissionTypeChanged: _onSubmissionTypeChanged,
                    onPickDueDate: _pickDueDate,
                    onTermChanged: _controller.setTermNumber,
                    onComponentChanged: _controller.setComponent,
                    onPublishChanged: _controller.setIsPublished,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
