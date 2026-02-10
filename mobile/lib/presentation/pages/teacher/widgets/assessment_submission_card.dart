import 'package:flutter/material.dart';

class AssessmentSubmissionCard extends StatelessWidget {
  final String studentName;
  final String studentUsername;
  final bool isSubmitted;
  final DateTime? submittedAt;
  final DateTime startedAt;
  final double finalScore;
  final VoidCallback onTap;

  const AssessmentSubmissionCard({
    super.key,
    required this.studentName,
    required this.studentUsername,
    required this.isSubmitted,
    this.submittedAt,
    required this.startedAt,
    required this.finalScore,
    required this.onTap,
  });

  String _formatDateTime(DateTime dt) {
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
            ? 12
            : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$month/$day/${dt.year} $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(1, 1, 1, 2.5),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFF8F9FA),
                child: Text(
                  studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Color(0xFF404040),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF202020),
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      studentUsername,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF999999),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      submittedAt != null
                          ? 'Submitted: ${_formatDateTime(submittedAt!)}'
                          : 'Started: ${_formatDateTime(startedAt)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF999999),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isSubmitted
                          ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                          : const Color(0xFFFFA726).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isSubmitted ? 'Submitted' : 'In Progress',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSubmitted
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFFA726),
                      ),
                    ),
                  ),
                  if (isSubmitted) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${finalScore % 1 == 0 ? finalScore.toInt() : finalScore.toStringAsFixed(1)} pts',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xFF2B2B2B),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFCCCCCC),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}