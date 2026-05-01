import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/transmutation_util.dart';
import 'package:likha/domain/grading/entities/period_grade.dart';

/// Large grade display banner shown at the top of the grade detail screen.
class OverallGradeBanner extends StatelessWidget {
  final PeriodGrade? quarterGrade;

  const OverallGradeBanner({super.key, required this.quarterGrade});

  @override
  Widget build(BuildContext context) {
    final hasGrade = quarterGrade?.transmutedGrade != null;
    final gradeDisplay = hasGrade ? '${quarterGrade!.transmutedGrade}' : '--';
    final descriptor = hasGrade
        ? TransmutationUtil.getDescriptor(quarterGrade!.transmutedGrade!)
        : 'No grade yet';

    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          gradeDisplay,
          style: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w700,
            color: AppColors.accentCharcoal,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          descriptor,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.foregroundTertiary,
          ),
        ),
      ],
    );
  }
}
