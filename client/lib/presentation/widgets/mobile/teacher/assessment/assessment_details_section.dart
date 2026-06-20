import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/validators.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/assessment_field.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assignment/shared_due_date_time_picker.dart';
import 'package:likha/presentation/widgets/shared/forms/assessment_switch_tile.dart';
import 'package:likha/presentation/widgets/shared/forms/form_decorators.dart';

class AssessmentDetailsSection extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController timeLimitController;
  final DateTime openAt;
  final DateTime closeAt;
  final bool showResultsImmediately;
  final bool isPublished;
  final bool isLoading;
  final ValueChanged<DateTime> onOpenAtChanged;
  final ValueChanged<DateTime> onCloseAtChanged;
  final ValueChanged<bool> onShowResultsChanged;
  final ValueChanged<bool> onIsPublishedChanged;
  final VoidCallback onAutoSave;
  final int? selectedQuarter;
  final String? selectedComponent;
  final bool isDepartmentalExam;
  final ValueChanged<int?>? onQuarterChanged;
  final ValueChanged<String?>? onComponentChanged;
  final ValueChanged<bool>? onDepartmentalExamChanged;
  final String? selectedTosId;
  final List<TableOfSpecifications> tosList;
  final ValueChanged<String?>? onTosChanged;

  const AssessmentDetailsSection({
    super.key,
    required this.formKey,
    required this.titleController,
    required this.descriptionController,
    required this.timeLimitController,
    required this.openAt,
    required this.closeAt,
    required this.showResultsImmediately,
    required this.isPublished,
    required this.isLoading,
    required this.onOpenAtChanged,
    required this.onCloseAtChanged,
    required this.onShowResultsChanged,
    required this.onIsPublishedChanged,
    required this.onAutoSave,
    this.selectedQuarter,
    this.selectedComponent,
    this.isDepartmentalExam = false,
    this.onQuarterChanged,
    this.onComponentChanged,
    this.onDepartmentalExamChanged,
    this.selectedTosId,
    this.tosList = const [],
    this.onTosChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assessment Details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AssessmentField(
                  label: 'Title',
                  controller: titleController,
                  icon: Icons.title_rounded,
                  validator: (v) => requiredFieldValidator(v, 'Title'),
                  onChanged: (_) => onAutoSave(),
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),
                AssessmentField(
                  label: 'Description (optional)',
                  controller: descriptionController,
                  maxLines: 3,
                  icon: Icons.description_rounded,
                  onChanged: (_) => onAutoSave(),
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),
                AssessmentField(
                  label: 'Time Limit (minutes)',
                  controller: timeLimitController,
                  icon: Icons.timer_rounded,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => onAutoSave(),
                  validator: (v) => positiveIntValidator(v, 'number of minutes'),
                  enabled: !isLoading,
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
                const SizedBox(height: 8),
                AssessmentSwitchTile(
                  title: 'Show results immediately',
                  subtitle: 'Students can see results right after submission',
                  value: showResultsImmediately,
                  onChanged: isLoading ? null : onShowResultsChanged,
                ),
                const SizedBox(height: 8),
                AssessmentSwitchTile(
                  title: 'Publish',
                  subtitle: 'Students can see this assessment right away',
                  value: isPublished,
                  onChanged: isLoading ? null : onIsPublishedChanged,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  initialValue: selectedQuarter,
                  decoration: assessmentInputDecoration('Quarter (for grading)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None')),
                    ...List.generate(
                      4,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text('Quarter ${i + 1}'),
                      ),
                    ),
                  ],
                  onChanged: isLoading ? null : onQuarterChanged,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  initialValue: selectedComponent,
                  decoration: assessmentInputDecoration('Grade Component'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('None')),
                    DropdownMenuItem(
                      value: 'written_work',
                      child: Text('Written Work'),
                    ),
                    DropdownMenuItem(
                      value: 'performance_task',
                      child: Text('Performance Task'),
                    ),
                    DropdownMenuItem(
                      value: 'period_assessment',
                      child: Text('Quarterly Assessment'),
                    ),
                  ],
                  onChanged: isLoading ? null : onComponentChanged,
                ),
                if (selectedComponent == 'period_assessment') ...[
                  const SizedBox(height: 8),
                  AssessmentSwitchTile(
                    title: 'Departmental Quarterly Exam',
                    subtitle: 'Mark as departmental quarterly exam',
                    value: isDepartmentalExam,
                    onChanged: isLoading ? null : onDepartmentalExamChanged,
                  ),
                ],
                if (tosList.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedTosId,
                    decoration:
                        assessmentInputDecoration('Link to TOS (optional)'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      ...tosList.map(
                        (tos) => DropdownMenuItem(
                          value: tos.id,
                          child: Text(
                            '${tos.title} (Grading Period ${tos.termNumber})',
                          ),
                        ),
                      ),
                    ],
                    onChanged: isLoading ? null : onTosChanged,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}