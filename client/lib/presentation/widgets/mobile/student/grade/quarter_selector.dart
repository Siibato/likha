import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/grading/entities/period_grade.dart';

/// Row of Q1–Q4 choice chips for switching the active grading period.
class QuarterSelector extends StatelessWidget {
  final int selectedQuarter;
  final List<PeriodGrade> quarterlyGrades;
  final void Function(int quarter) onChanged;

  const QuarterSelector({
    super.key,
    required this.selectedQuarter,
    required this.quarterlyGrades,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: List.generate(4, (index) {
        final quarter = index + 1;
        final isSelected = selectedQuarter == quarter;
        final hasData = quarterlyGrades.any(
          (g) => g.gradingPeriodNumber == quarter && g.transmutedGrade != null,
        );

        return ChoiceChip(
          label: Text('Q$quarter'),
          selected: isSelected,
          onSelected: (selected) {
            if (selected && quarter != selectedQuarter) onChanged(quarter);
          },
          selectedColor: AppColors.accentCharcoal,
          backgroundColor:
              hasData ? AppColors.borderLight : AppColors.backgroundTertiary,
          labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.foregroundSecondary,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide.none,
          showCheckmark: false,
        );
      }),
    );
  }
}
