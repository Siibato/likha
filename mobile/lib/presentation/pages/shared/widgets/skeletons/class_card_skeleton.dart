import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/shared/widgets/tokens/app_dimensions.dart';
import 'skeleton_box.dart';

/// Skeleton for ClassCard.
///
/// Mimics icon slot + title + subtitle + chevron layout.
/// Used by student/teacher/admin class list pages.
class ClassCardSkeleton extends StatelessWidget {
  const ClassCardSkeleton({super.key});

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
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon slot
            SkeletonBox(
              width: 36,
              height: 36,
              borderRadius: AppDimensions.kIconSlotRadius,
            ),
            SizedBox(width: 16),
            // Text column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  SkeletonBox(
                    width: double.infinity * 0.6,
                    height: 14,
                    borderRadius: 4,
                  ),
                  SizedBox(height: 10),
                  // Subtitle
                  SkeletonBox(
                    width: double.infinity * 0.4,
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
