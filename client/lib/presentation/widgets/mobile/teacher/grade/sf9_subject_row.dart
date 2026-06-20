import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/term_utils.dart';
import 'package:likha/domain/grading/entities/sf9.dart';

class Sf9SubjectRowWidget extends StatelessWidget {
  final Sf9SubjectRow row;
  final String? termType;

  const Sf9SubjectRowWidget({super.key, required this.row, this.termType});

  @override
  Widget build(BuildContext context) {
    final periodCount = periodCountFromType(termType);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              row.classTitle,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.accentCharcoal,
              ),
            ),
          ),
          ...List.generate(periodCount, (i) => _gradeChip(
            row.termGrades.length > i ? row.termGrades[i] : null,
          )),
          SizedBox(
            width: 48,
            child: Text(
              row.finalGrade?.toString() ?? '--',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: row.finalGrade != null
                    ? AppColors.accentCharcoal
                    : AppColors.foregroundLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradeChip(int? grade) {
    return SizedBox(
      width: 40,
      child: Text(
        grade?.toString() ?? '--',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: grade != null ? AppColors.accentCharcoal : AppColors.foregroundLight,
        ),
      ),
    );
  }
}
