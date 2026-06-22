import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/term_utils.dart';

class DesktopGradeTermChips extends StatelessWidget {
  final int selectedTerm;
  final ValueChanged<int> onTermChanged;
  final String? termType;

  const DesktopGradeTermChips({
    super.key,
    required this.selectedTerm,
    required this.onTermChanged,
    this.termType,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(termCountFromType(termType), (index) {
        final term = index + 1;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text('T$term'),
            selected: selectedTerm == term,
            onSelected: (selected) {
              if (selected) onTermChanged(term);
            },
            selectedColor: AppColors.foregroundDark,
            labelStyle: TextStyle(
              color: selectedTerm == term ? Colors.white : AppColors.foregroundPrimary,
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
