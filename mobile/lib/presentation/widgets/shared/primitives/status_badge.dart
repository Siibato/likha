import 'package:flutter/material.dart';
import '../tokens/app_decorations.dart';
import '../tokens/app_text_styles.dart';

/// A bordered or filled pill badge used for status labels.
///
/// Supports two variants:
/// - [BadgeVariant.outlined]: Border with light background
/// - [BadgeVariant.filled]: Solid colored background
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final BadgeVariant variant;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.variant = BadgeVariant.outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: variant == BadgeVariant.outlined
          ? AppDecorations.badgeOutlined()
          : AppDecorations.badgeFilled(color: color),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTextStyles.badgeLabelMd.copyWith(
              color: variant == BadgeVariant.outlined ? color : color,
            ),
          ),
        ],
      ),
    );
  }
}

enum BadgeVariant {
  outlined,
  filled,
}
