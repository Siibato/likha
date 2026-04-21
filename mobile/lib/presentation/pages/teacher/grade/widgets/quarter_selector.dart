import 'package:flutter/material.dart';

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
                      selectedColor: const Color(0xFF2B2B2B),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: selectedQuarter == q
                            ? Colors.white
                            : const Color(0xFF666666),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: selectedQuarter == q
                              ? const Color(0xFF2B2B2B)
                              : const Color(0xFFE0E0E0),
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
              color: const Color(0xFF666666),
              tooltip: 'Compute Grades',
              onPressed: onComputeGrades,
            ),
          if (onFinalGrades != null)
            IconButton(
              icon: const Icon(Icons.grade_outlined, size: 20),
              color: const Color(0xFF666666),
              tooltip: 'Final Grades',
              onPressed: onFinalGrades,
            ),
          if (onGradingSettings != null)
            IconButton(
              icon: const Icon(Icons.settings_outlined, size: 20),
              color: const Color(0xFF666666),
              tooltip: 'Grading Settings',
              onPressed: onGradingSettings,
            ),
          if (onDownload != null)
            IconButton(
              icon: const Icon(Icons.download_outlined, size: 20),
              color: const Color(0xFF666666),
              tooltip: 'Download Grades',
              onPressed: onDownload,
            ),
          if (onPrint != null)
            IconButton(
              icon: const Icon(Icons.print_outlined, size: 20),
              color: const Color(0xFF666666),
              tooltip: 'Print Grades',
              onPressed: onPrint,
            ),
        ],
      ),
    );
  }
}
