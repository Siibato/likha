import 'dart:convert';

import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/assignments/usecases/create_assignment.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assignment/assignment_grade_settings.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assignment/assignment_instructions_field.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assignment/assignment_points_field.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assignment/assignment_publish_settings.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assignment/assignment_submission_options.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assignment/assignment_title_field.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assignment/file_type_picker_sheet.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assignment/shared_due_date_time_picker.dart';
import 'package:likha/presentation/widgets/shared/forms/form_message.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';

class CreateAssignmentPage extends ConsumerStatefulWidget {
  final String classId;

  const CreateAssignmentPage({super.key, required this.classId});

  @override
  ConsumerState<CreateAssignmentPage> createState() =>
      _CreateAssignmentPageState();
}

class _CreateAssignmentPageState extends ConsumerState<CreateAssignmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  late final FleatherController _instructionsController;
  final _totalPointsController = TextEditingController(text: '100');
  final _maxFileSizeController = TextEditingController(text: '10');

  Set<String> _selectedFileTypes = {};
  bool _allowsTextSubmission = true;
  bool _allowsFileSubmission = false;
  DateTime _dueAt = DateTime.now().add(const Duration(days: 7));
  bool _isPublished = true;
  int? _quarter;
  String? _component = 'performance_task';
  bool _noSubmissionRequired = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _instructionsController = FleatherController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _instructionsController.dispose();
    _totalPointsController.dispose();
    _maxFileSizeController.dispose();
    super.dispose();
  }

  String _formatDateTimeForApi(DateTime dt) {
    final utc = dt.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}-'
        '${utc.month.toString().padLeft(2, '0')}-'
        '${utc.day.toString().padLeft(2, '0')}T'
        '${utc.hour.toString().padLeft(2, '0')}:'
        '${utc.minute.toString().padLeft(2, '0')}:'
        '${utc.second.toString().padLeft(2, '0')}';
  }

  Future<void> _showFileTypesPicker() async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => FileTypePickerSheet(initialSelection: _selectedFileTypes),
    );
    if (result != null) setState(() => _selectedFileTypes = result);
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    final totalPoints = int.tryParse(_totalPointsController.text.trim());
    if (totalPoints == null || totalPoints <= 0 || totalPoints > 1000) {
      setState(() => _formError = 'Total points must be between 1 and 1000');
      return;
    }

    String? allowedFileTypes;
    int? maxFileSizeMb;
    if (_allowsFileSubmission) {
      if (_selectedFileTypes.isNotEmpty) {
        allowedFileTypes = _selectedFileTypes.join(',');
      }
      final maxSize = int.tryParse(_maxFileSizeController.text.trim());
      if (maxSize != null && maxSize > 0) maxFileSizeMb = maxSize;
    }

    await ref.read(assignmentProvider.notifier).createAssignment(
          CreateAssignmentParams(
            classId: widget.classId,
            title: _titleController.text.trim(),
            instructions:
                jsonEncode(_instructionsController.document.toJson()),
            totalPoints: totalPoints,
            allowsTextSubmission: _allowsTextSubmission,
            allowsFileSubmission: _allowsFileSubmission,
            allowedFileTypes: allowedFileTypes,
            maxFileSizeMb: maxFileSizeMb,
            dueAt: _formatDateTimeForApi(_dueAt),
            isPublished: _isPublished,
            gradingPeriodNumber: _quarter,
            component: _component,
            noSubmissionRequired: _noSubmissionRequired,
          ),
        );

    if (!mounted) return;
    final state = ref.read(assignmentProvider);
    if (state.error != null) {
      setState(() => _formError = AppErrorMapper.toUserMessage(state.error));
      ref.read(assignmentProvider.notifier).clearMessages();
    } else {
      ref.read(assignmentProvider.notifier).clearMessages();
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignState = ref.watch(assignmentProvider);
    final isLoading = assignState.isLoading;

    return Scaffold(
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FormMessage(message: _formError, severity: MessageSeverity.error),
              const SizedBox(height: 16),
              AssignmentTitleField(
                controller: _titleController,
                enabled: !isLoading,
                onChanged: (_) => setState(() => _formError = null),
              ),
              const SizedBox(height: 16),
              AssignmentInstructionsField(
                controller: _instructionsController,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              AssignmentPointsField(
                controller: _totalPointsController,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              AssignmentSubmissionOptions(
                allowsTextSubmission: _allowsTextSubmission,
                allowsFileSubmission: _allowsFileSubmission,
                selectedFileTypes: _selectedFileTypes,
                maxFileSizeController: _maxFileSizeController,
                enabled: !isLoading,
                onTextToggle: (v) => setState(() => _allowsTextSubmission = v),
                onFileToggle: (v) => setState(() => _allowsFileSubmission = v),
                onPickFileTypes: _showFileTypesPicker,
              ),
              const SizedBox(height: 16),
              SharedDueDateTimePicker(
                label: 'Due Date',
                dateTime: _dueAt,
                icon: Icons.event_rounded,
                enabled: !isLoading,
                onChanged: (dt) => setState(() => _dueAt = dt),
              ),
              const SizedBox(height: 16),
              AssignmentGradeSettings(
                quarter: _quarter,
                component: _component,
                enabled: !isLoading,
                onQuarterChanged: (v) => setState(() => _quarter = v),
                onComponentChanged: (v) => setState(() => _component = v),
              ),
              const SizedBox(height: 8),
              AssignmentPublishSettings(
                noSubmissionRequired: _noSubmissionRequired,
                isPublished: _isPublished,
                enabled: !isLoading,
                onNoSubmissionChanged: (v) =>
                    setState(() => _noSubmissionRequired = v),
                onPublishChanged: (v) => setState(() => _isPublished = v),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading ? null : _handleCreate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentCharcoal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.borderLight,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Create Assignment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
