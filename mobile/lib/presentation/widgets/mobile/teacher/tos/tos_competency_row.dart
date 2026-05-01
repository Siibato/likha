import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';

class TosCompetencyRow extends StatelessWidget {
  final TosCompetency competency;
  final int totalDays;
  final String timeUnit;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TosCompetencyRow({
    super.key,
    required this.competency,
    required this.totalDays,
    this.timeUnit = 'days',
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final weight = totalDays > 0
        ? ((competency.timeUnitsTaught) / totalDays * 100).toStringAsFixed(1)
        : '0.0';

    return GestureDetector(
      onTap: onEdit,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (competency.competencyCode != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.borderLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        competency.competencyCode!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.foregroundSecondary,
                        ),
                      ),
                    ),
                  Text(
                    competency.competencyText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.accentCharcoal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${competency.timeUnitsTaught} $timeUnit taught',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.foregroundTertiary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$weight%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.foregroundSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onDelete != null)
              GestureDetector(
                onTap: onDelete,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.close, size: 18, color: AppColors.foregroundTertiary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
