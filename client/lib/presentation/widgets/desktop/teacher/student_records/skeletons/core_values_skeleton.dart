import 'package:flutter/material.dart';
import 'package:likha/core/constants/core_values_constants.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/term_utils.dart';
import 'package:likha/presentation/widgets/shared/skeletons/skeleton_box.dart';
import 'package:likha/presentation/widgets/shared/skeletons/skeleton_pulse.dart';

class CoreValuesSkeleton extends StatelessWidget {
  const CoreValuesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: SkeletonPulse(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: 200, height: 22, borderRadius: 4),
            const SizedBox(height: 20),
            Table(
              columnWidths: {
                0: const FlexColumnWidth(3),
                ...Map.fromEntries(List.generate(termCountFromType(null), (i) => MapEntry(i + 1, const FlexColumnWidth(1)))),
              },
              children: [
                TableRow(
                  children: List.generate(
                    termCountFromType(null) + 1,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: SkeletonBox(width: double.infinity, height: 14, borderRadius: 4),
                    ),
                  ),
                ),
                ...coreValueStatements.map((_) => TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: SkeletonBox(width: 200, height: 14, borderRadius: 4),
                    ),
                    ...List.generate(
                      termCountFromType(null),
                      (_) => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        child: SizedBox(
                          height: 36,
                          child: SkeletonBox(width: double.infinity, height: 36, borderRadius: 6),
                        ),
                      ),
                    ),
                  ],
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
