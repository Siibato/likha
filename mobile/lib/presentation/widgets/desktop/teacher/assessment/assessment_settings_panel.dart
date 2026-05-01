import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/providers/tos_provider.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assessment/assessment_question_type_editors.dart';

/// Left panel of the desktop assessment builder — assessment metadata form.
class AssessmentSettingsPanel extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleCtrl;
  final TextEditingController descriptionCtrl;
  final TextEditingController timeLimitCtrl;
  final DateTime openAt;
  final DateTime closeAt;
  final bool showResultsImmediately;
  final bool isPublished;
  final int? quarter;
  final String? component;
  final bool isDepartmentalExam;
  final String? linkedTosId;
  final bool isSaving;
  final TosState tosState;
  final VoidCallback onPickOpenAt;
  final VoidCallback onPickCloseAt;
  final void Function(bool) onShowResultsChanged;
  final void Function(bool) onPublishChanged;
  final void Function(int?) onQuarterChanged;
  final void Function(String?) onComponentChanged;
  final void Function(bool) onDepartmentalExamChanged;
  final void Function(String?) onLinkedTosChanged;
  final VoidCallback onAutoSave;

  const AssessmentSettingsPanel({
    super.key,
    required this.formKey,
    required this.titleCtrl,
    required this.descriptionCtrl,
    required this.timeLimitCtrl,
    required this.openAt,
    required this.closeAt,
    required this.showResultsImmediately,
    required this.isPublished,
    required this.quarter,
    required this.component,
    required this.isDepartmentalExam,
    required this.linkedTosId,
    required this.isSaving,
    required this.tosState,
    required this.onPickOpenAt,
    required this.onPickCloseAt,
    required this.onShowResultsChanged,
    required this.onPublishChanged,
    required this.onQuarterChanged,
    required this.onComponentChanged,
    required this.onDepartmentalExamChanged,
    required this.onLinkedTosChanged,
    required this.onAutoSave,
  });

  static String formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
            ? 12
            : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}, '
        '${dt.year} $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assessment Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.accentCharcoal,
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: titleCtrl,
              decoration: assessmentInputDecoration('Title'),
              enabled: !isSaving,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
              onChanged: (_) => onAutoSave(),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: descriptionCtrl,
              decoration: assessmentInputDecoration('Description (optional)'),
              maxLines: 3,
              enabled: !isSaving,
              onChanged: (_) => onAutoSave(),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: timeLimitCtrl,
              decoration: assessmentInputDecoration('Time Limit (minutes)'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              enabled: !isSaving,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Time limit is required';
                }
                final parsed = int.tryParse(v.trim());
                if (parsed == null || parsed <= 0) {
                  return 'Enter a valid number of minutes';
                }
                return null;
              },
              onChanged: (_) => onAutoSave(),
            ),
            const SizedBox(height: 16),

            _DateTimeField(
              label: 'Open Date',
              dateTime: openAt,
              isSaving: isSaving,
              onPick: onPickOpenAt,
            ),
            const SizedBox(height: 16),

            _DateTimeField(
              label: 'Close Date',
              dateTime: closeAt,
              isSaving: isSaving,
              onPick: onPickCloseAt,
            ),
            const SizedBox(height: 12),

            _AssessmentSwitchTile(
              title: 'Show results immediately',
              subtitle: 'Students can see results right after submission',
              value: showResultsImmediately,
              onChanged: isSaving ? null : onShowResultsChanged,
            ),
            const SizedBox(height: 8),

            _AssessmentSwitchTile(
              title: 'Publish immediately',
              subtitle: 'Students can see this assessment right away',
              value: isPublished,
              onChanged: isSaving ? null : onPublishChanged,
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<int?>(
              initialValue: quarter,
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
              onChanged: isSaving ? null : onQuarterChanged,
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String?>(
              initialValue: component,
              decoration: assessmentInputDecoration('Grade Component'),
              items: const [
                DropdownMenuItem(value: null, child: Text('None')),
                DropdownMenuItem(value: 'ww', child: Text('Written Work')),
                DropdownMenuItem(
                  value: 'pt',
                  child: Text('Performance Task'),
                ),
                DropdownMenuItem(
                  value: 'qa',
                  child: Text('Quarterly Assessment'),
                ),
              ],
              onChanged: isSaving ? null : onComponentChanged,
            ),

            if (component == 'qa') ...[
              const SizedBox(height: 8),
              _AssessmentSwitchTile(
                title: 'Departmental Exam',
                subtitle: 'Mark as departmental quarterly exam',
                value: isDepartmentalExam,
                onChanged: isSaving ? null : onDepartmentalExamChanged,
              ),
            ],

            if (tosState.tosList.isNotEmpty) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: linkedTosId,
                decoration: assessmentInputDecoration('Link to TOS (optional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ...tosState.tosList.map(
                    (tos) => DropdownMenuItem(
                      value: tos.id,
                      child: Text(
                        '${tos.title} (Q${tos.gradingPeriodNumber})',
                      ),
                    ),
                  ),
                ],
                onChanged: isSaving ? null : onLinkedTosChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  final String label;
  final DateTime dateTime;
  final bool isSaving;
  final VoidCallback onPick;

  const _DateTimeField({
    required this.label,
    required this.dateTime,
    required this.isSaving,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isSaving ? null : onPick,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: assessmentInputDecoration(label).copyWith(
          suffixIcon: const Icon(
            Icons.arrow_drop_down_rounded,
            color: AppColors.foregroundSecondary,
          ),
        ),
        child: Text(
          AssessmentSettingsPanel.formatDateTime(dateTime),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.accentCharcoal,
          ),
        ),
      ),
    );
  }
}

class _AssessmentSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final void Function(bool)? onChanged;

  const _AssessmentSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: SwitchListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.accentCharcoal,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.foregroundTertiary,
          ),
        ),
        value: value,
        activeThumbColor: AppColors.accentCharcoal,
        onChanged: onChanged,
      ),
    );
  }
}
