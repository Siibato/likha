import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/validators.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/assessment_field.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assignment/shared_due_date_time_picker.dart';
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormMessage(
            message: formError,
            severity: MessageSeverity.error,
          ),
          const SizedBox(height: 16),
          AssessmentField(
            label: 'Title',
            controller: titleController,
            icon: Icons.title_rounded,
            validator: (v) => requiredFieldValidator(v, 'Title'),
            enabled: !isLoading,
            onChanged: (_) => onClearFormError(),
          ),
          const SizedBox(height: 16),
          AssessmentField(
            label: 'Description (optional)',
            controller: descriptionController,
            icon: Icons.description_outlined,
            maxLines: 3,
            enabled: !isLoading,
            onChanged: (_) => onClearFormError(),
          ),
          const SizedBox(height: 16),
          AssessmentField(
            label: 'Time Limit (minutes)',
            controller: timeLimitController,
            icon: Icons.timer_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) => positiveIntValidator(v, 'number of minutes'),
            enabled: !isLoading,
            onChanged: (_) => onClearFormError(),
          ),
          const SizedBox(height: 16),
          SharedDueDateTimePicker(
            label: 'Open Date',
            dateTime: openAt,
            icon: Icons.calendar_today_rounded,
            enabled: !isLoading,
            onChanged: onOpenAtChanged,
          ),
          const SizedBox(height: 16),
          SharedDueDateTimePicker(
            label: 'Close Date',
            dateTime: closeAt,
            icon: Icons.event_rounded,
            enabled: !isLoading,
            onChanged: onCloseAtChanged,
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
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
              activeThumbColor: AppColors.accentCharcoal,
              onChanged: isLoading ? null : onShowResultsChanged,
            ),
          ),
        ],
      ),
    );
  }
}
