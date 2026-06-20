import 'package:flutter/material.dart';

import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/formatters.dart';

/// Desktop info chips showing file count and last-updated date.
class MaterialInfoChips extends StatelessWidget {
  final dynamic material;

  const MaterialInfoChips({super.key, required this.material});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _buildChip(
          Icons.attach_file_rounded,
          '${material.files.length} file(s)',
        ),
        _buildChip(
          Icons.schedule_rounded,
          'Updated ${Formatters.formatDateShort(material.updatedAt)}',
        ),
      ],
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.foregroundTertiary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.foregroundSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
