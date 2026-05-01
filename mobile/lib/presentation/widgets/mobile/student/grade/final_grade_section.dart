import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/transmutation_util.dart';
import 'package:likha/domain/grading/entities/period_grade.dart';

/// Shows the computed final grade when at least 2 quarters have grades.
/// Returns [SizedBox.shrink] when the condition is not met.
class FinalGradeSection extends StatelessWidget {
  final List<PeriodGrade> quarterlyGrades;

  const FinalGradeSection({super.key, required this.quarterlyGrades});

  @override
  Widget build(BuildContext context) {
    final withGrades =
        quarterlyGrades.where((g) => g.transmutedGrade != null).toList();

    if (withGrades.length < 2) return const SizedBox.shrink();

    final sum = withGrades.fold<int>(0, (acc, g) => acc + g.transmutedGrade!);
    final finalGrade =
        double.parse((sum / withGrades.length).toStringAsFixed(1));
    final finalGradeRounded = finalGrade.round();
    final descriptor = TransmutationUtil.getDescriptor(finalGradeRounded);
    final descriptorColor =
        TransmutationUtil.getDescriptorColor(finalGradeRounded);

    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: AppColors.borderLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Final Grade',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.foregroundDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$finalGradeRounded',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentCharcoal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(descriptorColor),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      descriptor,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
