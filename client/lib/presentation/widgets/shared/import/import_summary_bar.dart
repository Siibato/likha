import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/data/models/import/import_preview_model.dart';

class ImportSummaryBar extends StatelessWidget {
  final PreviewResponseModel preview;

  const ImportSummaryBar({super.key, required this.preview});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          _SummaryItem(
            icon: Icons.check_circle_outline,
            color: AppColors.semanticSuccess,
            label: 'Valid',
            count: preview.validCount,
          ),
          const SizedBox(width: 24),
          _SummaryItem(
            icon: Icons.warning_amber_rounded,
            color: AppColors.accentAmberBorder,
            label: 'Warnings',
            count: preview.warningCount,
          ),
          const SizedBox(width: 24),
          _SummaryItem(
            icon: Icons.error_outline,
            color: AppColors.semanticError,
            label: 'Errors',
            count: preview.errorCount,
          ),
          const SizedBox(width: 24),
          Text(
            'Total: ${preview.rows.length}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int count;

  const _SummaryItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          '$label: $count',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
