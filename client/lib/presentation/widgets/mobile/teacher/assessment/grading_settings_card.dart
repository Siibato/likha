import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// Inline grading settings card for AssessmentDetailPage.
///
/// Shows the current quarter and grade component in view mode, and exposes
/// dropdowns to edit them. The parent page manages the editing state.
class GradingSettingsCard extends StatelessWidget {
  final int? gradingPeriodNumber;
  final String? component;
  final bool isEditing;

  final int? editingGradingPeriod;
  final String? editingComponent;

  final VoidCallback onEdit;
  final void Function(int? period, String? component) onSave;
  final VoidCallback onCancel;
  final void Function(int?) onPeriodChanged;
  final void Function(String?) onComponentChanged;

  const GradingSettingsCard({
    super.key,
    required this.gradingPeriodNumber,
    required this.component,
    required this.isEditing,
    required this.editingGradingPeriod,
    required this.editingComponent,
    required this.onEdit,
    required this.onSave,
    required this.onCancel,
    required this.onPeriodChanged,
    required this.onComponentChanged,
  });

  String _componentDisplayName(String c) {
    switch (c) {
      case 'written_work':
        return 'Written Work';
      case 'performance_task':
        return 'Performance Task';
      case 'quarterly_assessment':
        return 'Quarterly Assessment';
      default:
        return c;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grading Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.foregroundPrimary,
                ),
              ),
              if (!isEditing)
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.foregroundPrimary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!isEditing) ...[
            Row(
              children: [
                Icon(
                  Icons.grain_rounded,
                  size: 16,
                  color: gradingPeriodNumber != null
                      ? AppColors.foregroundPrimary
                      : AppColors.foregroundTertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  gradingPeriodNumber != null
                      ? 'Quarter $gradingPeriodNumber'
                      : 'No quarter assigned',
                  style: TextStyle(
                    fontSize: 14,
                    color: gradingPeriodNumber != null
                        ? AppColors.foregroundPrimary
                        : AppColors.foregroundTertiary,
                  ),
                ),
                if (component != null) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.category_rounded,
                      size: 16, color: AppColors.foregroundPrimary),
                  const SizedBox(width: 8),
                  Text(
                    _componentDisplayName(component!),
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.foregroundPrimary),
                  ),
                ],
              ],
            ),
          ] else ...[
            DropdownButtonFormField<int?>(
              initialValue: editingGradingPeriod,
              decoration: const InputDecoration(
                labelText: 'Quarter (for grading)',
                labelStyle: TextStyle(
                    fontSize: 14, color: AppColors.foregroundTertiary),
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('None')),
                DropdownMenuItem(value: 1, child: Text('Quarter 1')),
                DropdownMenuItem(value: 2, child: Text('Quarter 2')),
                DropdownMenuItem(value: 3, child: Text('Quarter 3')),
                DropdownMenuItem(value: 4, child: Text('Quarter 4')),
              ],
              onChanged: onPeriodChanged,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: editingComponent,
              decoration: const InputDecoration(
                labelText: 'Grade Component',
                labelStyle: TextStyle(
                    fontSize: 14, color: AppColors.foregroundTertiary),
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('None')),
                DropdownMenuItem(
                    value: 'written_work', child: Text('Written Work')),
                DropdownMenuItem(
                    value: 'performance_task',
                    child: Text('Performance Task')),
                DropdownMenuItem(
                    value: 'quarterly_assessment',
                    child: Text('Quarterly Assessment')),
              ],
              onChanged: onComponentChanged,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onSave(editingGradingPeriod, editingComponent),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentCharcoal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Save Settings'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
