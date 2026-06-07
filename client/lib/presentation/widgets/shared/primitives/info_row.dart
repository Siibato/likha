import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import '../tokens/app_text_styles.dart';

/// A label-value row used in card details and info sections.
///
/// Renders a fixed-width label on the left, with the value (or custom widget) on the right.
/// Optionally displays a leading icon and/or an edit button.
class InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;
  final IconData? icon;
  final VoidCallback? onEdit;

  const InfoRow({
    super.key,
    required this.label,
    this.value,
    this.valueWidget,
    this.icon,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    assert(value != null || valueWidget != null, 'Either value or valueWidget must be provided');

    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 20,
            color: AppColors.foregroundDark,
          ),
          const SizedBox(width: 12),
        ],
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: AppTextStyles.cardSubtitleMd.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: valueWidget ??
              Text(
                value ?? '',
                style: AppTextStyles.inputText,
                overflow: TextOverflow.ellipsis,
              ),
        ),
        if (onEdit != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.backgroundTertiary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.edit_outlined,
                size: 16,
                color: AppColors.foregroundDark,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
