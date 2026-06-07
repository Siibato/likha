import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/grading/entities/sf9.dart';

class Sf9SubjectRowWidget extends StatelessWidget {
  final Sf9SubjectRow row;

  const Sf9SubjectRowWidget({super.key, required this.row});

  @override
  Widget build(BuildContext context) {
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
          _gradeChip(row.q1),
          _gradeChip(row.q2),
          _gradeChip(row.q3),
          _gradeChip(row.q4),
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
