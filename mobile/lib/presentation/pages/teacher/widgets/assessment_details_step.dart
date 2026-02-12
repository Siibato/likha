import 'package:flutter/material.dart';
import 'package:likha/presentation/pages/teacher/widgets/assessment_field.dart';
import 'package:likha/presentation/pages/teacher/widgets/assessment_date_time_picker.dart';

class AssessmentDetailsStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController timeLimitController;
  final DateTime openAt;
  final DateTime closeAt;
  final bool showResultsImmediately;
  final bool isLoading;
  final ValueChanged<DateTime> onOpenAtChanged;
  final ValueChanged<DateTime> onCloseAtChanged;
  final ValueChanged<bool> onShowResultsChanged;
  final VoidCallback onCreateAssessment;

  const AssessmentDetailsStep({
    super.key,
    required this.formKey,
    required this.titleController,
    required this.descriptionController,
    required this.timeLimitController,
    required this.openAt,
    required this.closeAt,
    required this.showResultsImmediately,
    required this.isLoading,
    required this.onOpenAtChanged,
    required this.onCloseAtChanged,
    required this.onShowResultsChanged,
    required this.onCreateAssessment,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AssessmentField(
            label: 'Title',
            controller: titleController,
            icon: Icons.title_rounded,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Title is required';
              }
              return null;
            },
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),
          AssessmentField(
            label: 'Description (optional)',
            controller: descriptionController,
            maxLines: 3,
            icon: Icons.description_rounded,
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),
          AssessmentField(
            label: 'Time Limit (minutes)',
            controller: timeLimitController,
            icon: Icons.timer_rounded,
            keyboardType: TextInputType.number,
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
          ),
          const SizedBox(height: 16),
          AssessmentDateTimePicker(
            label: 'Open Date',
            dateTime: openAt,
            icon: Icons.calendar_today_rounded,
            enabled: !isLoading,
            onChanged: onOpenAtChanged,
          ),
          const SizedBox(height: 16),
          AssessmentDateTimePicker(
            label: 'Close Date',
            dateTime: closeAt,
            icon: Icons.event_rounded,
            enabled: !isLoading,
            onChanged: onCloseAtChanged,
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              title: const Text(
                'Show results immediately',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2B2B2B),
                ),
              ),
              subtitle: const Text(
                'Students can see results right after submission',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF999999),
                ),
              ),
              value: showResultsImmediately,
              activeColor: const Color(0xFF2B2B2B),
              onChanged: isLoading ? null : onShowResultsChanged,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : onCreateAssessment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B2B2B),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE0E0E0),
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
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Create & Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}