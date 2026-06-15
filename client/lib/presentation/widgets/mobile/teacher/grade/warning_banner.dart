import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

class WarningBanner extends StatelessWidget {
  final String message;
  final IconData icon;

  const WarningBanner({
    super.key,
    required this.message,
    this.icon = Icons.warning_amber_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentAmberSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accentAmber,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentAmberBorder, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.accentAmberBorder,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}