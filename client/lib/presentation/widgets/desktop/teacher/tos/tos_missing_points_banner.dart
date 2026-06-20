import 'package:flutter/material.dart';

import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';

/// Banner shown below the TOS grid when assigned items don't match the target.
class TosMissingPointsBanner extends StatelessWidget {
  final List<TosCompetency> competencies;
  final TableOfSpecifications tos;

  const TosMissingPointsBanner({
    super.key,
    required this.competencies,
    required this.tos,
  });

  @override
  Widget build(BuildContext context) {
    final totalDays =
        competencies.fold<int>(0, (sum, c) => sum + c.timeUnitsTaught);

    final isBloomsMode = tos.classificationMode == 'blooms';
    final assigned = competencies.fold<int>(0, (sum, c) {
      if (totalDays == 0) return sum;
      final targetItems =
          (c.timeUnitsTaught / totalDays * tos.totalItems).round();
      if (isBloomsMode) {
        final r = c.rememberingCount ??
            (targetItems * tos.rememberingPercentage / 100).round();
        final u = c.understandingCount ??
            (targetItems * tos.understandingPercentage / 100).round();
        final ap = c.applyingCount ??
            (targetItems * tos.applyingPercentage / 100).round();
        final an = c.analyzingCount ??
            (targetItems * tos.analyzingPercentage / 100).round();
        final e = c.evaluatingCount ??
            (targetItems * tos.evaluatingPercentage / 100).round();
        final bl = c.creatingCount ??
            (targetItems * tos.creatingPercentage / 100).round();
        return sum + r + u + ap + an + e + bl;
      }
      final easy = c.easyCount ??
          (targetItems * tos.easyPercentage / 100).round();
      final medium = c.mediumCount ??
          (targetItems * tos.mediumPercentage / 100).round();
      final hard = c.hardCount ??
          (targetItems * tos.hardPercentage / 100).round();
      return sum + easy + medium + hard;
    });

    final diff = tos.totalItems - assigned;
    if (diff == 0) return const SizedBox.shrink();

    final message = diff > 0
        ? '$diff item${diff == 1 ? '' : 's'} under target. '
            'Total assigned: $assigned / ${tos.totalItems}'
        : '${-diff} item${-diff == 1 ? '' : 's'} over target. '
            'Total assigned: $assigned / ${tos.totalItems}';

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.accentAmber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.accentAmber),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_outlined,
                size: 16, color: AppColors.accentAmber),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.accentAmber,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
