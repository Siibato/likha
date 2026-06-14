import 'package:flutter/material.dart';

import 'package:likha/core/theme/app_colors.dart';

/// Full-width outlined button used in the mobile TOS detail page.
class TosOutlinedButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const TosOutlinedButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accentCharcoal,
          side: const BorderSide(color: AppColors.borderLight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
