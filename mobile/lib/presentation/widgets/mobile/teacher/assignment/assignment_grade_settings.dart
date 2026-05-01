import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// Quarter and grade-component dropdowns for assignment grading linkage.
class AssignmentGradeSettings extends StatelessWidget {
  final int? quarter;
  final String? component;
  final bool enabled;
  final void Function(int?) onQuarterChanged;
  final void Function(String?) onComponentChanged;

  const AssignmentGradeSettings({
    super.key,
    required this.quarter,
    required this.component,
    required this.enabled,
    required this.onQuarterChanged,
    required this.onComponentChanged,
  });

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontSize: 14,
        color: AppColors.foregroundTertiary,
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppColors.accentCharcoal, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<int?>(
          initialValue: quarter,
          decoration: _decoration('Quarter (for grading)'),
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
          onChanged: enabled ? onQuarterChanged : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String?>(
          initialValue: component,
          decoration: _decoration('Grade Component'),
          items: const [
            DropdownMenuItem(value: null, child: Text('None')),
            DropdownMenuItem(value: 'written_work', child: Text('Written Work')),
            DropdownMenuItem(
              value: 'performance_task',
              child: Text('Performance Task'),
            ),
            DropdownMenuItem(
              value: 'quarterly_assessment',
              child: Text('Quarterly Assessment'),
            ),
          ],
          onChanged: enabled ? onComponentChanged : null,
        ),
      ],
    );
  }
}
