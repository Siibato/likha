import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

class AssessmentStatusCard extends StatelessWidget {
  final bool isPublished;
  final bool resultsReleased;
  final VoidCallback? onTap;

  const AssessmentStatusCard({
    super.key,
    required this.isPublished,
    required this.resultsReleased,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    String? actionHint;

    if (!isPublished) {
      statusColor = AppColors.foregroundPrimary;
      statusText = 'Draft';
      statusIcon = Icons.edit_note_rounded;
      actionHint = 'Tap to publish';
    } else if (resultsReleased) {
      statusColor = AppColors.foregroundTertiary;
      statusText = 'Results Released';
      statusIcon = Icons.check_circle_rounded;
    } else {
      statusColor = AppColors.foregroundSecondary;
      statusText = 'Published';
      statusIcon = Icons.public_rounded;
      actionHint = 'Tap to release results';
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
                        color: AppColors.foregroundSecondary,
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