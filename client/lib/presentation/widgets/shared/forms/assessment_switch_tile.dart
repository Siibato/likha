import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// Shared switch tile for assessment forms (mobile + desktop).
class AssessmentSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final void Function(bool)? onChanged;

  const AssessmentSwitchTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: SwitchListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.accentCharcoal,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.foregroundTertiary,
          ),
        ),
        value: value,
        activeThumbColor: AppColors.accentCharcoal,
        onChanged: onChanged,
      ),
    );
  }
}
