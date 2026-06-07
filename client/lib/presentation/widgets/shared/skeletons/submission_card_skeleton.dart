import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/shared/tokens/app_dimensions.dart';
import 'skeleton_box.dart';

/// Skeleton for SubmissionCard.
///
/// Mimics avatar + name/username + status badges + score layout.
/// Used by assessment and assignment submissions pages.
class SubmissionCardSkeleton extends StatelessWidget {
  const SubmissionCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.kCardSmListSpacing),
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius:
            BorderRadius.circular(AppDimensions.kCardSmOuterRadius),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          1,
          1,
          1,
          AppDimensions.kCardSmShellBottomInset,
        ),
        padding: const EdgeInsets.all(AppDimensions.kCardPadSm),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(AppDimensions.kCardSmInnerRadius),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar circle
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.backgroundTertiary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            // Text column
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Student name
                  SkeletonBox(
                    width: double.infinity * 0.55,
                    height: 13,
                    borderRadius: 4,
                  ),
                  SizedBox(height: 6),
                  // Username
                  SkeletonBox(
                    width: double.infinity * 0.4,
                    height: 11,
                    borderRadius: 4,
                  ),
                ],
              ),
            ),
            // Score badge
            const SizedBox(width: 12),
            const SkeletonBox(
              width: 45,
              height: 20,
              borderRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}
