import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/labels.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assignment/assignment_date_time_field.dart';
import 'package:likha/presentation/widgets/shared/forms/form_decorators.dart';
import 'package:likha/presentation/widgets/shared/forms/form_message.dart';
import 'package:likha/presentation/widgets/shared/forms/rich_text_field.dart';

class AssignmentCreateForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final FleatherController instructionsController;
  final TextEditingController totalPointsController;
  final String submissionType;
  final DateTime dueAt;
  final int? quarter;
  final String? component;
  final bool isPublished;
  final String? formError;
  final bool isSaving;
  final VoidCallback onSave;
  final ValueChanged<String> onSubmissionTypeChanged;
  final VoidCallback onPickDueDate;
  final ValueChanged<int?> onQuarterChanged;
  final ValueChanged<String?> onComponentChanged;
  final ValueChanged<bool> onPublishChanged;

  const AssignmentCreateForm({
    super.key,
    required this.formKey,
    required this.titleController,
    required this.instructionsController,
    required this.totalPointsController,
    required this.submissionType,
    required this.dueAt,
    required this.quarter,
    required this.component,
    required this.isPublished,
    this.formError,
    required this.isSaving,
    required this.onSave,
    required this.onSubmissionTypeChanged,
    required this.onPickDueDate,
    required this.onQuarterChanged,
    required this.onComponentChanged,
    required this.onPublishChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormMessage(
              message: formError,
              severity: MessageSeverity.error,
            ),
            if (formError != null) const SizedBox(height: 12),

            // Title
            TextFormField(
              controller: titleController,
              decoration: assessmentInputDecoration(
                'Title',
                focusedBorderColor: AppColors.foregroundPrimary,
                labelColor: AppColors.foregroundSecondary,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),

            // Instructions
            RichTextField(
              controller: instructionsController,
              label: 'Instructions',
              icon: Icons.description_outlined,
              enabled: true,
              minHeight: 120,
            ),
            const SizedBox(height: 16),

            // Total Points
            TextFormField(
              controller: totalPointsController,
              decoration: assessmentInputDecoration(
                'Total Points',
                focusedBorderColor: AppColors.foregroundPrimary,
                labelColor: AppColors.foregroundSecondary,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Points required';
                final pts = int.tryParse(v.trim());
                if (pts == null || pts <= 0) return 'Must be greater than 0';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Submission Type
            DropdownButtonFormField<String>(
              initialValue: submissionType,
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
                if (v != null) onSubmissionTypeChanged(v);
              },
            ),
            const SizedBox(height: 16),

            // Due Date
            AssignmentDateTimeField(
              label: 'Due Date',
              dateTime: dueAt,
              onPick: onPickDueDate,
            ),
            const SizedBox(height: 16),

            // Quarter
            DropdownButtonFormField<int?>(
              initialValue: quarter,
              decoration: assessmentInputDecoration(
                'Quarter (optional)',
                focusedBorderColor: AppColors.foregroundPrimary,
                labelColor: AppColors.foregroundSecondary,
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('None')),
                DropdownMenuItem(value: 1, child: Text('Quarter 1')),
                DropdownMenuItem(value: 2, child: Text('Quarter 2')),
                DropdownMenuItem(value: 3, child: Text('Quarter 3')),
                DropdownMenuItem(value: 4, child: Text('Quarter 4')),
              ],
              onChanged: onQuarterChanged,
            ),
            const SizedBox(height: 16),

            // Grade Component
            DropdownButtonFormField<String?>(
              initialValue: component,
              decoration: assessmentInputDecoration(
                'Grade Component (optional)',
                focusedBorderColor: AppColors.foregroundPrimary,
                labelColor: AppColors.foregroundSecondary,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                ...['ww', 'pt', 'qa'].map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(componentLabel(c)),
                  ),
                ),
              ],
              onChanged: onComponentChanged,
            ),
            const SizedBox(height: 16),

            // Publish toggle
            SwitchListTile(
              value: isPublished,
              onChanged: onPublishChanged,
              title: const Text(
                'Publish Immediately',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.foregroundDark,
                ),
              ),
              subtitle: Text(
                isPublished
                    ? 'Students will see this assignment right away'
                    : 'Save as draft, publish later',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.foregroundTertiary,
                ),
              ),
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.foregroundPrimary,
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: isSaving ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.foregroundPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Create Assignment',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
