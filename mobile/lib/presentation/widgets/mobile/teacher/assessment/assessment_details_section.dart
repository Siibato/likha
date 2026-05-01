import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/assessment_field.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assignment/shared_due_date_time_picker.dart';

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
  final VoidCallback? onCreateAssessment;
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
    required this.onCreateAssessment,
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
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.borderLight,
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
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.borderLight,
                width: 1,
              ),
            ),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              title: const Text(
                'Publish',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foregroundPrimary,
                ),
              ),
              subtitle: const Text(
                'Students can see this assessment right away',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.foregroundTertiary,
                ),
              ),
              value: isPublished,
              activeThumbColor: AppColors.accentCharcoal,
              onChanged: isLoading ? null : onIsPublishedChanged,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int?>(
            initialValue: selectedQuarter,
            decoration: InputDecoration(
              labelText: 'Quarter (for grading)',
              labelStyle: const TextStyle(
                fontSize: 14,
                color: AppColors.foregroundTertiary,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.borderLight,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.borderLight,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.accentCharcoal,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('None')),
              ...List.generate(4, (i) => DropdownMenuItem(value: i + 1, child: Text('Quarter ${i + 1}'))),
            ],
            onChanged: isLoading ? null : onQuarterChanged,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            initialValue: selectedComponent,
            decoration: InputDecoration(
              labelText: 'Grade Component',
              labelStyle: const TextStyle(
                fontSize: 14,
                color: AppColors.foregroundTertiary,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.borderLight,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.borderLight,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.accentCharcoal,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('None')),
              DropdownMenuItem(value: 'written_work', child: Text('Written Work')),
              DropdownMenuItem(value: 'performance_task', child: Text('Performance Task')),
              DropdownMenuItem(value: 'quarterly_assessment', child: Text('Quarterly Assessment')),
            ],
            onChanged: isLoading ? null : onComponentChanged,
          ),
          if (selectedComponent == 'quarterly_assessment') ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.borderLight,
                  width: 1,
                ),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                title: const Text(
                  'Departmental Quarterly Exam',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foregroundPrimary,
                  ),
                ),
                subtitle: const Text(
                  'Mark as departmental quarterly exam',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.foregroundTertiary,
                  ),
                ),
                value: isDepartmentalExam,
                activeThumbColor: AppColors.accentCharcoal,
                onChanged: isLoading ? null : onDepartmentalExamChanged,
              ),
            ),
          ],
          if (tosList.isNotEmpty) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: selectedTosId,
              decoration: InputDecoration(
                labelText: 'Link to TOS (optional)',
                labelStyle: const TextStyle(
                  fontSize: 14,
                  color: AppColors.foregroundTertiary,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.borderLight,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.borderLight,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.accentCharcoal,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                ...tosList.map((tos) => DropdownMenuItem(
                      value: tos.id,
                      child: Text('${tos.title} (Grading Period ${tos.gradingPeriodNumber})'),
                    )),
              ],
              onChanged: isLoading ? null : onTosChanged,
            ),
          ],
        ],
      ),
    );
  }
}