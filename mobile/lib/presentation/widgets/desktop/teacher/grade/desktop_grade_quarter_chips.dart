import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

class DesktopGradeQuarterChips extends StatelessWidget {
  final int selectedQuarter;
  final ValueChanged<int> onQuarterChanged;

  const DesktopGradeQuarterChips({
    super.key,
    required this.selectedQuarter,
    required this.onQuarterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(4, (index) {
        final quarter = index + 1;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text('Q$quarter'),
            selected: selectedQuarter == quarter,
            onSelected: (selected) {
              if (selected) onQuarterChanged(quarter);
            },
            selectedColor: AppColors.foregroundDark,
            labelStyle: TextStyle(
              color: selectedQuarter == quarter ? Colors.white : AppColors.foregroundPrimary,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppColors.borderLight),
          ),
        );
      }),
    );
  }
}
