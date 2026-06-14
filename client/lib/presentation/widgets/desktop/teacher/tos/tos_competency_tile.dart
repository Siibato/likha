import 'package:flutter/material.dart';

import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';

/// Desktop competency tile used in the TOS detail page competency list.
class TosCompetencyTile extends StatelessWidget {
  final TosCompetency competency;
  final String timeUnit;
  final VoidCallback onTap;

  const TosCompetencyTile({
    super.key,
    required this.competency,
    required this.timeUnit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    competency.competencyText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.foregroundPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${competency.timeUnitsTaught} $_unitLabel',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.foregroundSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onTap,
              icon: const Icon(Icons.edit_outlined, size: 18),
              color: AppColors.foregroundSecondary,
              tooltip: 'Edit',
            ),
          ],
        ),
      ),
    );
  }

  String get _unitLabel {
    if (timeUnit == 'hours') {
      return competency.timeUnitsTaught == 1 ? 'hour taught' : 'hours taught';
    }
    return competency.timeUnitsTaught == 1 ? 'day taught' : 'days taught';
  }
}
