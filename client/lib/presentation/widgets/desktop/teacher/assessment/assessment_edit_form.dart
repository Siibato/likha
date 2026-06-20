import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assessment/assessment_date_time_field.dart';
import 'package:likha/presentation/widgets/shared/forms/form_decorators.dart';
import 'package:likha/presentation/widgets/shared/forms/form_message.dart';

class AssessmentEditForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController timeLimitController;
  final DateTime openAt;
  final DateTime closeAt;
  final bool showResultsImmediately;
  final bool isLoading;
  final String? formError;
  final ValueChanged<DateTime> onOpenAtChanged;
  final ValueChanged<DateTime> onCloseAtChanged;
  final ValueChanged<bool> onShowResultsChanged;
  final VoidCallback onClearFormError;

  const AssessmentEditForm({
    super.key,
    required this.formKey,
    required this.titleController,
    required this.descriptionController,
    required this.timeLimitController,
    required this.openAt,
    required this.closeAt,
    required this.showResultsImmediately,
    required this.isLoading,
    this.formError,
    required this.onOpenAtChanged,
    required this.onCloseAtChanged,
    required this.onShowResultsChanged,
    required this.onClearFormError,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight, width: 1),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormMessage(
              message: formError,
              severity: MessageSeverity.error,
            ),
            // Title
            TextFormField(
              controller: titleController,
              decoration: assessmentInputDecoration(
                'Title',
                focusedBorderColor: AppColors.foregroundPrimary,
                labelColor: AppColors.foregroundSecondary,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
              enabled: !isLoading,
              onChanged: (_) => onClearFormError(),
            ),
            const SizedBox(height: 20),

            // Description
            TextFormField(
              controller: descriptionController,
              decoration: assessmentInputDecoration(
                'Description (optional)',
                focusedBorderColor: AppColors.foregroundPrimary,
                labelColor: AppColors.foregroundSecondary,
              ),
              maxLines: 3,
              enabled: !isLoading,
              onChanged: (_) => onClearFormError(),
            ),
            const SizedBox(height: 20),

            // Time Limit
            TextFormField(
              controller: timeLimitController,
              decoration: assessmentInputDecoration(
                'Time Limit (minutes)',
                focusedBorderColor: AppColors.foregroundPrimary,
                labelColor: AppColors.foregroundSecondary,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Time limit is required';
                }
                final parsed = int.tryParse(value.trim());
                if (parsed == null || parsed <= 0) {
                  return 'Enter a valid number of minutes';
                }
                return null;
              },
              enabled: !isLoading,
              onChanged: (_) => onClearFormError(),
            ),
            const SizedBox(height: 20),

            // Open Date
            AssessmentDateTimeField(
              label: 'Open Date',
              value: openAt,
              enabled: !isLoading,
              onChanged: onOpenAtChanged,
            ),
            const SizedBox(height: 20),

            // Close Date
            AssessmentDateTimeField(
              label: 'Close Date',
              value: closeAt,
              enabled: !isLoading,
              onChanged: onCloseAtChanged,
            ),
            const SizedBox(height: 24),

            // Show Results Immediately
            Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight, width: 1),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                title: const Text(
                  'Show results immediately',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.foregroundPrimary,
                  ),
                ),
                subtitle: const Text(
                  'Students can see results right after submission',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.foregroundTertiary,
                  ),
                ),
                value: showResultsImmediately,
                activeThumbColor: AppColors.foregroundPrimary,
                onChanged: isLoading ? null : onShowResultsChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
