import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/shared/widgets/tokens/app_dimensions.dart';
import 'skeleton_box.dart';

/// Skeleton for MaterialCard (Learning Material Card).
///
/// Mimics BaseCardSm shape: icon slot + title + file count + chevron.
/// Used by student material list page and teacher material list page.
class MaterialCardSkeleton extends StatelessWidget {
  const MaterialCardSkeleton({super.key});

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
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon slot
            SkeletonBox(
              width: 36,
              height: 36,
              borderRadius: 10,
            ),
            SizedBox(width: 14),
            // Text column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  SkeletonBox(
                    width: double.infinity * 0.65,
                    height: 13,
                    borderRadius: 4,
                  ),
                  SizedBox(height: 8),
                  // File count
                  SkeletonBox(
                    width: double.infinity * 0.45,
                    height: 11,
                    borderRadius: 4,
                  ),
                ],
              ),
            ),
            // Chevron
            SizedBox(width: 12),
            SkeletonBox(
              width: 16,
              height: 16,
              borderRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}
