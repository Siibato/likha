import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/assessment_statistics.dart';

class QuestionAnalysisCard extends StatelessWidget {
  final int index;
  final QuestionStatistics stats;

  const QuestionAnalysisCard({
    super.key,
    required this.index,
    required this.stats,
  });

  String _questionTypeLabel(String type) {
    switch (type) {
      case 'multiple_choice':
        return 'MC';
      case 'identification':
        return 'ID';
      case 'enumeration':
        return 'ENUM';
      default:
        return type;
    }
  }

  Color _getPerformanceColor(double percentage) {
    if (percentage >= 75) {
      return AppColors.semanticSuccess;
    } else if (percentage >= 50) {
      return AppColors.accentAmber;
    } else {
      return AppColors.semanticError;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = stats.correctPercentage;
    final barColor = _getPerformanceColor(pct);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.accentCharcoal,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 2.5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundTertiary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Q${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppColors.foregroundPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundTertiary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _questionTypeLabel(stats.questionType),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.foregroundSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${stats.points} pt${stats.points != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.foregroundTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              stats.questionText,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.foregroundPrimary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 10,
                      backgroundColor: AppColors.backgroundTertiary,
                      valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${pct.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: barColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${stats.correctCount} correct • ${stats.incorrectCount} incorrect',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.foregroundTertiary,
                fontWeight: FontWeight.w500,
                ),
            ),
          ],
        ),
      ),
    );
  }
}