import 'package:flutter/material.dart';
import 'package:likha/domain/assessments/entities/submission.dart';

class ScoreSummaryCard extends StatelessWidget {
  final StudentResult result;

  const ScoreSummaryCard({super.key, required this.result});

  String _formatDateTime(DateTime dt) {
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
            ? 12
            : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$month/$day/$year $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final percentage = result.totalPoints > 0
        ? (result.finalScore / result.totalPoints * 100)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(
              'Your Score',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  result.finalScore % 1 == 0
                      ? result.finalScore.toInt().toString()
                      : result.finalScore.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2B2B2B),
                    letterSpacing: -1.5,
                  ),
                ),
                Text(
                  ' / ${result.totalPoints}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFE0E0E0),
                ),
              ),
              child: Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2B2B2B),
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: result.totalPoints > 0
                    ? result.finalScore / result.totalPoints
                    : 0,
                minHeight: 10,
                backgroundColor: const Color(0xFFF0F0F0),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2B2B2B)),
              ),
            ),
            if (result.submittedAt != null) ...[
              const SizedBox(height: 16),
              Text(
                'Submitted on ${_formatDateTime(result.submittedAt!)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}