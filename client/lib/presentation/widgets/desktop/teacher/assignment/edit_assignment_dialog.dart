import 'dart:convert';

import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/formatters.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/domain/assignments/usecases/update_assignment.dart';
import 'package:likha/presentation/providers/assignment/assignment_list_provider.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assignment/assignment_date_time_field.dart';
import 'package:likha/presentation/widgets/shared/dialogs/styled_dialog.dart';
import 'package:likha/presentation/widgets/shared/forms/form_decorators.dart';
import 'package:likha/presentation/widgets/shared/forms/rich_text_field.dart';

/// Desktop dialog for editing an assignment.
class EditAssignmentDialog extends ConsumerStatefulWidget {
  final Assignment assignment;

  const EditAssignmentDialog({
    super.key,
    required this.assignment,
  });

  @override
  ConsumerState<EditAssignmentDialog> createState() =>
      _EditAssignmentDialogState();
}

class _EditAssignmentDialogState extends ConsumerState<EditAssignmentDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _totalPointsController;
  late final FleatherController _instructionsController;
  late DateTime _dueAt;
  late String _submissionType;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.assignment.title);
    _totalPointsController =
        TextEditingController(text: widget.assignment.totalPoints.toString());
    _dueAt = widget.assignment.dueAt;

    final instructions = widget.assignment.instructions;
    if (instructions.isNotEmpty) {
      try {
        final doc = ParchmentDocument.fromJson(jsonDecode(instructions));
        _instructionsController = FleatherController(document: doc);
      } catch (_) {
        _instructionsController = FleatherController();
      }
    } else {
      _instructionsController = FleatherController();
    }

    if (widget.assignment.allowsTextSubmission &&
        widget.assignment.allowsFileSubmission) {
      _submissionType = 'text_or_file';
    } else if (widget.assignment.allowsTextSubmission) {
      _submissionType = 'text';
    } else if (widget.assignment.allowsFileSubmission) {
      _submissionType = 'file';
    } else {
      _submissionType = 'text_or_file';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _totalPointsController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _onSubmissionTypeChanged(String value) {
    setState(() => _submissionType = value);
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueAt,
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
      initialTime: TimeOfDay.fromDateTime(_dueAt),
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

    setState(() {
      _dueAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _handleSave() {
    final newTitle = _titleController.text.trim();
    if (newTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    final pts = int.tryParse(_totalPointsController.text.trim());
    if (pts == null || pts <= 0 || pts > 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Total points must be between 1 and 1000')),
      );
      return;
    }

    Navigator.pop(context);

    final instructionsPlainText =
        _instructionsController.document.toPlainText().trim();
    final instructionsJson = instructionsPlainText.isEmpty
        ? null
        : jsonEncode(_instructionsController.document.toJson());

    final allowsText = _submissionType == 'text_or_file' || _submissionType == 'text';
    final allowsFile = _submissionType == 'text_or_file' || _submissionType == 'file';

    ref.read(assignmentListProvider.notifier).updateAssignment(
      UpdateAssignmentParams(
        assignmentId: widget.assignment.id,
        title: newTitle,
        instructions: instructionsJson,
        totalPoints: pts,
        dueAt: formatDateTimeForApi(_dueAt),
        allowsTextSubmission: allowsText,
        allowsFileSubmission: allowsFile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      title: 'Edit Assignment',
      maxWidth: 680,
      maxHeight: MediaQuery.of(context).size.height * 0.85,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            TextFormField(
              controller: _titleController,
              decoration: assessmentInputDecoration(
                'Title',
                focusedBorderColor: AppColors.foregroundPrimary,
                labelColor: AppColors.foregroundSecondary,
              ),
            ),
            const SizedBox(height: 16),
            RichTextField(
              controller: _instructionsController,
              label: 'Instructions',
              icon: Icons.description_outlined,
              minHeight: 250,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _totalPointsController,
              decoration: assessmentInputDecoration(
                'Total Points',
                focusedBorderColor: AppColors.foregroundPrimary,
                labelColor: AppColors.foregroundSecondary,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            AssignmentDateTimeField(
              label: 'Due Date',
              dateTime: _dueAt,
              onPick: _pickDueDate,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _submissionType,
              decoration: assessmentInputDecoration(
                'Submission Type',
                focusedBorderColor: AppColors.foregroundPrimary,
                labelColor: AppColors.foregroundSecondary,
              ),
              items: const [
                DropdownMenuItem(value: 'text_or_file', child: Text('Text or File')),
                DropdownMenuItem(value: 'text', child: Text('Text Only')),
                DropdownMenuItem(value: 'file', child: Text('File Only')),
              ],
              onChanged: (v) {
                if (v != null) _onSubmissionTypeChanged(v);
              },
            ),
          ],
        ),
      actions: [
        StyledDialogAction(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        StyledDialogAction(
          label: 'Save Changes',
          isPrimary: true,
          onPressed: _handleSave,
        ),
      ],
    );
  }
}
