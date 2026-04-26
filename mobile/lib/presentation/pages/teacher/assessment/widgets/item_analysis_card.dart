import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/assessment_statistics.dart';
import 'package:likha/presentation/pages/teacher/assessment/widgets/distractor_table.dart';

class ItemAnalysisCard extends StatelessWidget {
  final int index;
  final ItemAnalysis item;

  const ItemAnalysisCard({
    super.key,
    required this.index,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Q# + type + verdict badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentCharcoal,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Q${index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.questionText,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.foregroundPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_typeLabel(item.questionType)} | ${item.points} pt${item.points == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.foregroundTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _VerdictBadge(verdict: item.verdict),
            ],
          ),
          const SizedBox(height: 14),
          // Indices
          Row(
            children: [
              Expanded(
                child: _IndexChip(
                  label: 'Difficulty (p)',
                  value: item.difficultyIndex.toStringAsFixed(2),
                  sublabel: item.difficultyLabel,
                  color: _difficultyColor(item.difficultyIndex),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _IndexChip(
                  label: 'Discrimination (D)',
                  value: item.discriminationIndex.toStringAsFixed(2),
                  sublabel: item.discriminationLabel,
                  color: _discriminationColor(item.discriminationIndex),
                ),
              ),
            ],
          ),
          // Distractor table for MC questions
          if (item.distractors != null && item.distractors!.isNotEmpty)
            DistractorTable(distractors: item.distractors!),
        ],
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'multiple_choice':
        return 'MC';
      case 'identification':
        return 'ID';
      case 'enumeration':
        return 'EN';
      default:
        return type.toUpperCase();
    }
  }

  Color _difficultyColor(double p) {
    if (p >= 0.81 || p <= 0.20) return AppColors.semanticError;
    if (p >= 0.61 || p <= 0.40) return AppColors.accentAmber;
    return AppColors.semanticSuccess;
  }

  Color _discriminationColor(double d) {
    if (d >= 0.40) return AppColors.semanticSuccess;
    if (d >= 0.30) return AppColors.accentCharcoal;
    if (d >= 0.20) return AppColors.accentAmber;
    return AppColors.semanticError;
  }
}

class _VerdictBadge extends StatelessWidget {
  final String verdict;

  const _VerdictBadge({required this.verdict});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (verdict.toLowerCase()) {
      'retain' => (AppColors.semanticSuccess, 'RETAIN'),
      'revise' => (AppColors.accentAmber, 'REVISE'),
      'discard' => (AppColors.semanticError, 'DISCARD'),
      _ => (AppColors.foregroundTertiary, verdict.toUpperCase()),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _IndexChip extends StatelessWidget {
  final String label;
  final String value;
  final String sublabel;
  final Color color;

  const _IndexChip({
    required this.label,
    required this.value,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.foregroundTertiary,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.foregroundPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  sublabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
