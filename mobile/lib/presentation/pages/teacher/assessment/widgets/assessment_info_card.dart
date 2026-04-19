import 'package:flutter/material.dart';
import 'package:likha/presentation/utils/formatters.dart';

class AssessmentInfoCard extends StatelessWidget {
  final String? description;
  final int timeLimitMinutes;
  final int totalPoints;
  final int questionCount;
  final int submissionCount;
  final DateTime openAt;
  final DateTime closeAt;
  final bool showResultsImmediately;
  final bool canEdit;
  final VoidCallback? onEdit;

  const AssessmentInfoCard({
    super.key,
    this.description,
    required this.timeLimitMinutes,
    required this.totalPoints,
    required this.questionCount,
    required this.submissionCount,
    required this.openAt,
    required this.closeAt,
    required this.showResultsImmediately,
    required this.canEdit,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canEdit ? onEdit : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Assessment Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF202020),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                if (canEdit)
                  Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: Colors.grey[400],
                  ),
              ],
            ),
            if (description != null && description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                description!,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF666666),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
            ],
            const SizedBox(height: 14),
            _InfoRow(
              icon: Icons.timer_outlined,
              label: 'Time Limit',
              value: '$timeLimitMinutes minutes',
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.star_outline_rounded,
              label: 'Total Points',
              value: '$totalPoints points',
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.help_outline_rounded,
              label: 'Questions',
              value: '$questionCount',
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.people_outline_rounded,
              label: 'Submissions',
              value: '$submissionCount',
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 14),
            _InfoRow(
              icon: Icons.calendar_today_rounded,
              label: 'Opens',
              value: formatDateTimeDisplay(openAt),
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.event_rounded,
              label: 'Closes',
              value: formatDateTimeDisplay(closeAt),
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.visibility_outlined,
              label: 'Show Results',
              value: showResultsImmediately ? 'Immediately' : 'After release',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF666666),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2B2B2B),
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}