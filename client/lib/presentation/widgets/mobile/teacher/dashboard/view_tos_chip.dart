import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

class ViewTosChip extends StatelessWidget {
  final VoidCallback onTap;

  const ViewTosChip({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.accentAmberSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.accentAmberBorder),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.table_chart_outlined, size: 16, color: AppColors.accentCharcoal),
            SizedBox(width: 6),
            Text(
              'View Linked TOS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.accentCharcoal,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.accentCharcoal),
          ],
        ),
      ),
    );
  }
}
