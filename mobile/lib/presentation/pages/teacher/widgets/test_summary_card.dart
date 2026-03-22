import 'package:flutter/material.dart';
import 'package:likha/domain/assessments/entities/assessment_statistics.dart';

class TestSummaryCard extends StatelessWidget {
  final TestSummary summary;

  const TestSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Test Summary',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF202020),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: 'Mean Difficulty',
                  value: summary.meanDifficulty.toStringAsFixed(2),
                  sublabel: _difficultyLabel(summary.meanDifficulty),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  label: 'Mean Discrimination',
                  value: summary.meanDiscrimination.toStringAsFixed(2),
                  sublabel: _discriminationLabel(summary.meanDiscrimination),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _VerdictChip(
                label: 'Retain',
                count: summary.retainCount,
                color: const Color(0xFF4CAF50),
              ),
              const SizedBox(width: 8),
              _VerdictChip(
                label: 'Revise',
                count: summary.reviseCount,
                color: const Color(0xFFF9A825),
              ),
              const SizedBox(width: 8),
              _VerdictChip(
                label: 'Discard',
                count: summary.discardCount,
                color: const Color(0xFFE57373),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 12),
          _InfoLine(label: 'Items Analyzed', value: '${summary.totalItemsAnalyzed}'),
          const SizedBox(height: 6),
          _InfoLine(label: 'Upper Group (27%)', value: '${summary.upperGroupSize} students'),
          const SizedBox(height: 6),
          _InfoLine(label: 'Lower Group (27%)', value: '${summary.lowerGroupSize} students'),
        ],
      ),
    );
  }

  String _difficultyLabel(double p) {
    if (p >= 0.81) return 'Very Easy';
    if (p >= 0.61) return 'Easy';
    if (p >= 0.41) return 'Average';
    if (p >= 0.21) return 'Difficult';
    return 'Very Difficult';
  }

  String _discriminationLabel(double d) {
    if (d >= 0.40) return 'Very Good';
    if (d >= 0.30) return 'Good';
    if (d >= 0.20) return 'Needs Revision';
    return 'Discard';
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final String sublabel;

  const _StatBox({
    required this.label,
    required this.value,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF999999),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2B2B2B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerdictChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _VerdictChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF666666),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2B2B2B),
          ),
        ),
      ],
    );
  }
}
