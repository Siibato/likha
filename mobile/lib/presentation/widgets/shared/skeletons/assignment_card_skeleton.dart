import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/shared/tokens/app_dimensions.dart';
import 'skeleton_box.dart';

/// Skeleton for AssignmentCard.
///
/// Mimics icon slot + title + info chips + status badges + chevron layout.
/// Used by student assignment list page.
class AssignmentCardSkeleton extends StatelessWidget {
  const AssignmentCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.kCardListSpacing),
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius:
            BorderRadius.circular(AppDimensions.kCardOuterRadius),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          1,
          1,
          1,
          AppDimensions.kCardShellBottomInset,
        ),
        padding: const EdgeInsets.all(AppDimensions.kCardPadMd),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(AppDimensions.kCardInnerRadius),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: icon + title + badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon slot
                SkeletonBox(
                  width: 36,
                  height: 36,
                  borderRadius: AppDimensions.kIconSlotRadius,
                ),
                SizedBox(width: 16),
                // Title column
                Expanded(
                  child: SkeletonBox(
                    width: double.infinity * 0.65,
                    height: 14,
                    borderRadius: 4,
                  ),
                ),
                // Right badges
                SizedBox(width: 12),
                SkeletonBox(
                  width: 60,
                  height: 18,
                  borderRadius: 6,
                ),
              ],
            ),
            SizedBox(height: 12),
            // Info chips row
            Row(
              children: [
                SkeletonBox(
                  width: 50,
                  height: 11,
                  borderRadius: 4,
                ),
                SizedBox(width: 14),
                SkeletonBox(
                  width: 50,
                  height: 11,
                  borderRadius: 4,
                ),
                SizedBox(width: 14),
                SkeletonBox(
                  width: 50,
                  height: 11,
                  borderRadius: 4,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
