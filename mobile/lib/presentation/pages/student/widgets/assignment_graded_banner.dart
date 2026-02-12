import 'package:flutter/material.dart';

class AssignmentGradedBanner extends StatelessWidget {
  final int score;
  final int totalPoints;
  final String? feedback;

  const AssignmentGradedBanner({
    super.key,
    required this.score,
    required this.totalPoints,
    this.feedback,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (score / totalPoints * 100).round();
    final isPassing = percentage >= 60;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPassing
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFEEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPassing
              ? const Color(0xFF34A853).withValues(alpha: 0.3)
              : const Color(0xFFEA4335).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.grading_rounded,
                color: isPassing
                    ? const Color(0xFF34A853)
                    : const Color(0xFFEA4335),
                size: 22,
              ),
              const SizedBox(width: 10),
              const Text(
                'Graded',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2B2B2B),
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isPassing
                      ? const Color(0xFF34A853)
                      : const Color(0xFFEA4335),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$score / $totalPoints',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          if (feedback != null && feedback!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Feedback:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF2B2B2B),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              feedback!,
              style: const TextStyle(
                color: Color(0xFF2B2B2B),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
