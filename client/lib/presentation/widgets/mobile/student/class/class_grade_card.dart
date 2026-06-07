import 'package:flutter/material.dart';
import 'package:likha/core/utils/transmutation_util.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/providers/student_class_grades_provider.dart';
import 'package:likha/presentation/widgets/shared/cards/base_card_sm.dart';

class ClassGradeCard extends StatelessWidget {
  final ClassGradeData classGrade;
  final VoidCallback onTap;

  const ClassGradeCard({
    super.key,
    required this.classGrade,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasGrade = classGrade.latestGrade != null;
    final gradeDisplay = hasGrade ? '${classGrade.latestGrade}' : '--';
    final descriptor = classGrade.latestDescriptor;
    final badgeColor = hasGrade
        ? TransmutationUtil.getDescriptorColor(classGrade.latestGrade!)
        : 0xFFCCCCCC;

    return BaseCardSm(
      margin: const EdgeInsets.only(bottom: 14),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  classGrade.className,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foregroundDark,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasGrade
                      ? 'Q${classGrade.latestPeriod}'
                      : 'No grades yet',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.foregroundTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                gradeDisplay,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentCharcoal,
                ),
              ),
              if (hasGrade) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(badgeColor),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    descriptor,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
