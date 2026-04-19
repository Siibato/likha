import 'package:flutter/material.dart';
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
        border: Border.all(color: const Color(0xFFE0E0E0)),
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
                  color: const Color(0xFF2B2B2B),
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
                        color: Color(0xFF2B2B2B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_typeLabel(item.questionType)} | ${item.points} pt${item.points == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF999999),
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
    if (p >= 0.81 || p <= 0.20) return const Color(0xFFE57373);
    if (p >= 0.61 || p <= 0.40) return const Color(0xFFF9A825);
    return const Color(0xFF4CAF50);
  }

  Color _discriminationColor(double d) {
    if (d >= 0.40) return const Color(0xFF4CAF50);
    if (d >= 0.30) return const Color(0xFF2196F3);
    if (d >= 0.20) return const Color(0xFFF9A825);
    return const Color(0xFFE57373);
  }
}

class _VerdictBadge extends StatelessWidget {
  final String verdict;

  const _VerdictBadge({required this.verdict});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (verdict.toLowerCase()) {
      'retain' => (const Color(0xFF4CAF50), 'RETAIN'),
      'revise' => (const Color(0xFFF9A825), 'REVISE'),
      'discard' => (const Color(0xFFE57373), 'DISCARD'),
      _ => (const Color(0xFF999999), verdict.toUpperCase()),
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
        color: const Color(0xFFF8F9FA),
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
              color: Color(0xFF999999),
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
                  color: Color(0xFF2B2B2B),
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
