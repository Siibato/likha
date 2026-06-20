import 'package:flutter/material.dart';

import 'package:likha/core/theme/app_colors.dart';

/// A single row inside the desktop TOS settings panel.
class TosSettingsRow extends StatelessWidget {
  final String label;
  final String value;

  const TosSettingsRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.foregroundSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
