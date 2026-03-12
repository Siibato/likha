import 'package:flutter/material.dart';

enum DetailStatus {
  notYetOpen,
  available,
  resumable,
  closed,
  pendingResults,
  resultsAvailable,
}

class AssessmentStatusBanner extends StatelessWidget {
  final DetailStatus status;
  final DateTime? openAt;
  final DateTime? closeAt;

  const AssessmentStatusBanner({
    super.key,
    required this.status,
    this.openAt,
    this.closeAt,
  });

  String _formatDateTime(DateTime dt) {
    // Convert UTC to device local time before formatting
    final local = dt.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour > 12
        ? local.hour - 12
        : local.hour == 0
            ? 12
            : local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$month/$day/$year $hour:$minute $period';
  }

  (Color, IconData, String, String) _getStatusData() {
    switch (status) {
      case DetailStatus.notYetOpen:
        return (
          const Color(0xFF808080),
          Icons.schedule_rounded,
          'Not Yet Open',
          openAt != null ? 'Opens on ${_formatDateTime(openAt!)}' : 'Opening soon',
        );
      case DetailStatus.available:
        return (
          const Color(0xFF34A853),
          Icons.play_circle_outline_rounded,
          'Available',
          'Start before the deadline',
        );
      case DetailStatus.resumable:
        return (
          const Color(0xFFFFBD59),
          Icons.play_arrow_rounded,
          'In Progress',
          'You\'ve already started this assessment',
        );
      case DetailStatus.closed:
        return (
          const Color(0xFF999999),
          Icons.lock_outline_rounded,
          'Assessment Closed',
          'The deadline has passed',
        );
      case DetailStatus.pendingResults:
        return (
          const Color(0xFF666666),
          Icons.hourglass_empty_rounded,
          'Results Pending',
          'Your submission is being reviewed',
        );
      case DetailStatus.resultsAvailable:
        return (
          const Color(0xFF34A853),
          Icons.check_circle_outline_rounded,
          'Results Available',
          'View your score below',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bgColor, icon, title, subtitle) = _getStatusData();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 24, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: bgColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF666666),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
