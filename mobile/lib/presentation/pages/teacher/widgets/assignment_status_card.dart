import 'package:flutter/material.dart';

class AssignmentStatusCard extends StatelessWidget {
  final bool isPublished;
  final DateTime dueAt;
  final VoidCallback? onTap;

  const AssignmentStatusCard({
    super.key,
    required this.isPublished,
    required this.dueAt,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    String? actionHint;

    if (!isPublished) {
      statusColor = const Color(0xFFFFA726);
      statusText = 'Draft';
      statusIcon = Icons.edit_note_rounded;
      actionHint = 'Tap to publish';
    } else {
      final now = DateTime.now();
      if (now.isBefore(dueAt)) {
        statusColor = const Color(0xFF4CAF50);
        statusText = 'Published - Open';
        statusIcon = Icons.public_rounded;
      } else {
        statusColor = const Color(0xFF42A5F5);
        statusText = 'Published - Past Due';
        statusIcon = Icons.event_busy_rounded;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: statusColor,
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                      fontSize: 16,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (actionHint != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      actionHint,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: statusColor,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}