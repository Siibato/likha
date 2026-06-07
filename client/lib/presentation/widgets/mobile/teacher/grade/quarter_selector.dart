import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

class QuarterSelector extends StatelessWidget {
  final int selectedQuarter;
  final Function(int) onQuarterChanged;
  final VoidCallback? onComputeGrades;
  final VoidCallback? onFinalGrades;
  final VoidCallback? onGradingSettings;
  final VoidCallback? onDownload;
  final VoidCallback? onPrint;

  const QuarterSelector({
    super.key,
    required this.selectedQuarter,
    required this.onQuarterChanged,
    this.onComputeGrades,
    this.onFinalGrades,
    this.onGradingSettings,
    this.onDownload,
    this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 4, 6),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(4, (i) {
                  final q = i + 1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('Q$q'),
                      selected: selectedQuarter == q,
                      selectedColor: AppColors.accentCharcoal,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: selectedQuarter == q
                            ? Colors.white
                            : AppColors.foregroundSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: selectedQuarter == q
                              ? AppColors.accentCharcoal
                              : AppColors.borderLight,
                        ),
                      ),
                      onSelected: (_) => onQuarterChanged(q),
                    ),
                  );
                }),
              ),
            ),
          ),
          if (onComputeGrades != null)
            IconButton(
              icon: const Icon(Icons.calculate_outlined, size: 20),
              color: AppColors.foregroundSecondary,
              tooltip: 'Compute Grades',
              onPressed: onComputeGrades,
            ),
          if (onFinalGrades != null)
            IconButton(
              icon: const Icon(Icons.grade_outlined, size: 20),
              color: AppColors.foregroundSecondary,
              tooltip: 'Final Grades',
              onPressed: onFinalGrades,
            ),
          if (onGradingSettings != null)
            IconButton(
              icon: const Icon(Icons.settings_outlined, size: 20),
              color: AppColors.foregroundSecondary,
              tooltip: 'Grading Settings',
              onPressed: onGradingSettings,
            ),
          if (onDownload != null)
            IconButton(
              icon: const Icon(Icons.download_outlined, size: 20),
              color: AppColors.foregroundSecondary,
              tooltip: 'Download Grades',
              onPressed: onDownload,
            ),
          if (onPrint != null)
            IconButton(
              icon: const Icon(Icons.print_outlined, size: 20),
              color: AppColors.foregroundSecondary,
              tooltip: 'Print Grades',
              onPressed: onPrint,
            ),
        ],
      ),
    );
  }
}
