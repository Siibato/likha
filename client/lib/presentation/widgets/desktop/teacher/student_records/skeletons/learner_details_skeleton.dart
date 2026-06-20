import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/shared/skeletons/skeleton_box.dart';
import 'package:likha/presentation/widgets/shared/skeletons/skeleton_pulse.dart';

class LearnerDetailsSkeleton extends StatelessWidget {
  const LearnerDetailsSkeleton({super.key});

  Widget _fieldSkeleton(double width) {
    return SizedBox(
      width: width,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 60, height: 12, borderRadius: 4),
          SizedBox(height: 6),
          SkeletonBox(width: double.infinity, height: 36, borderRadius: 8),
        ],
      ),
    );
  }

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
            const Row(
              children: [
                SkeletonBox(width: 200, height: 22, borderRadius: 4),
                Spacer(),
                SkeletonBox(width: 80, height: 36, borderRadius: 8),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _fieldSkeleton(220),
                _fieldSkeleton(100),
                _fieldSkeleton(100),
                _fieldSkeleton(200),
                _fieldSkeleton(200),
                _fieldSkeleton(180),
                _fieldSkeleton(220),
                _fieldSkeleton(300),
                _fieldSkeleton(220),
                _fieldSkeleton(220),
                _fieldSkeleton(220),
                _fieldSkeleton(180),
                _fieldSkeleton(180),
                _fieldSkeleton(180),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
