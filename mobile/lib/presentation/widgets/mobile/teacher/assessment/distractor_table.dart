import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/assessment_statistics.dart';

class DistractorTable extends StatelessWidget {
  final List<DistractorAnalysis> distractors;

  const DistractorTable({super.key, required this.distractors});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              'Distractor Analysis',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.foregroundSecondary,
              ),
            ),
          ),
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.borderLight),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                child: const Text('Choice', style: _headerStyle),
                ),
                SizedBox(
                  width: 44,
                  child: const Text('Up', style: _headerStyle, textAlign: TextAlign.center),
                ),
                SizedBox(
                  width: 44,
                  child: const Text('Low', style: _headerStyle, textAlign: TextAlign.center),
                ),
                SizedBox(
                  width: 44,
                  child: const Text('%', style: _headerStyle, textAlign: TextAlign.center),
                ),
                SizedBox(
                  width: 32,
                  child: const Text('', style: _headerStyle),
                ),
              ],
            ),
          ),
          // Rows
          ...distractors.map((d) => _DistractorRow(distractor: d)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.foregroundTertiary,
  );
}

class _DistractorRow extends StatelessWidget {
  final DistractorAnalysis distractor;

  const _DistractorRow({required this.distractor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                if (distractor.isCorrect)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.star_rounded, size: 14, color: AppColors.accentAmber),
                  ),
                Expanded(
                  child: Text(
                    distractor.choiceText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: distractor.isCorrect ? FontWeight.w600 : FontWeight.w400,
                      color: AppColors.foregroundPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '${distractor.upperCount}',
              style: const TextStyle(fontSize: 12, color: AppColors.foregroundPrimary),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '${distractor.lowerCount}',
              style: const TextStyle(fontSize: 12, color: AppColors.foregroundPrimary),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '${distractor.totalPercentage.toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 12, color: AppColors.foregroundPrimary),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 32,
            child: Icon(
              distractor.isEffective
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              size: 16,
              color: distractor.isEffective
                  ? AppColors.semanticSuccess
                  : AppColors.semanticError,
            ),
          ),
        ],
      ),
    );
  }
}
