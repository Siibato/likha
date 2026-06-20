import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/term_utils.dart';
import 'package:likha/domain/grading/entities/term_grade.dart';

/// Row of T1–T4 choice chips for switching the active term.
class TermSelector extends StatelessWidget {
  final int selectedTerm;
  final List<TermGrade> termGrades;
  final void Function(int term) onChanged;
  final String? termType;

  const TermSelector({
    super.key,
    required this.selectedTerm,
    required this.termGrades,
    required this.onChanged,
    this.termType,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: List.generate(termCountFromType(termType), (index) {
        final term = index + 1;
        final isSelected = selectedTerm == term;
        final hasData = termGrades.any(
          (g) => g.termNumber == term && g.transmutedGrade != null,
        );

        return ChoiceChip(
          label: Text('T$term'),
          selected: isSelected,
          onSelected: (selected) {
            if (selected && term != selectedTerm) onChanged(term);
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
