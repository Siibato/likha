import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/shared/skeletons/skeleton_box.dart';
import 'package:likha/presentation/widgets/shared/skeletons/skeleton_pulse.dart';

const _skeletonMonths = [
  'June', 'July', 'August', 'September', 'October', 'November',
  'December', 'January', 'February', 'March', 'April',
];

class AttendanceSkeleton extends StatelessWidget {
  const AttendanceSkeleton({super.key});

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
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  children: List.generate(
                    5,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: SkeletonBox(width: double.infinity, height: 14, borderRadius: 4),
                    ),
                  ),
                ),
                ..._skeletonMonths.map((_) => TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: SkeletonBox(width: 80, height: 14, borderRadius: 4),
                    ),
                    ...List.generate(
                      3,
                      (_) => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        child: SizedBox(
                          height: 36,
                          child: SkeletonBox(width: double.infinity, height: 36, borderRadius: 6),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: SizedBox(),
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
