import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/shared/tokens/app_dimensions.dart';
import 'skeleton_box.dart';

/// Skeleton for AssessmentCard (complex multi-section card).
///
/// Mimics header + description + info chips + date rows + action hint layout.
/// Used by student assessment list page.
class AssessmentCardSkeleton extends StatelessWidget {
  const AssessmentCardSkeleton({super.key});

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
        padding: const EdgeInsets.all(AppDimensions.kCardPadLg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(AppDimensions.kCardInnerRadius),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: title + badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SkeletonBox(
                    width: double.infinity * 0.7,
                    height: 16,
                    borderRadius: 4,
                  ),
                ),
                SizedBox(width: 12),
                SkeletonBox(
                  width: 80,
                  height: 22,
                  borderRadius: 8,
                ),
              ],
            ),
            SizedBox(height: 12),
            // Description (2 lines)
            SkeletonBox(
              width: double.infinity * 0.9,
              height: 12,
              borderRadius: 4,
            ),
            SizedBox(height: 4),
            SkeletonBox(
              width: double.infinity * 0.7,
              height: 12,
              borderRadius: 4,
            ),
            SizedBox(height: 12),
            // Info chips (3 items)
            Row(
              children: [
                SkeletonBox(
                  width: 50,
                  height: 18,
                  borderRadius: 4,
                ),
                SizedBox(width: 14),
                SkeletonBox(
                  width: 50,
                  height: 18,
                  borderRadius: 4,
                ),
                SizedBox(width: 14),
                SkeletonBox(
                  width: 50,
                  height: 18,
                  borderRadius: 4,
                ),
              ],
            ),
            SizedBox(height: 12),
            // Date rows (2x)
            SkeletonBox(
              width: double.infinity * 0.75,
              height: 11,
              borderRadius: 4,
            ),
            SizedBox(height: 8),
            SkeletonBox(
              width: double.infinity * 0.75,
              height: 11,
              borderRadius: 4,
            ),
            SizedBox(height: 12),
            // Action hint
            Align(
              alignment: Alignment.centerRight,
              child: SkeletonBox(
                width: 100,
                height: 11,
                borderRadius: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
