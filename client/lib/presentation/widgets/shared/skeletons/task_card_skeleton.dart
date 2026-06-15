import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/shared/tokens/app_dimensions.dart';
import 'skeleton_box.dart';

/// Skeleton for TaskCard.
///
/// Mimics left color bar + title + meta info + status badge layout.
/// Used by student tasks page.
class TaskCardSkeleton extends StatelessWidget {
  const TaskCardSkeleton({super.key});

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left color bar
            SkeletonBox(
              width: 4,
              height: 70,
              borderRadius: 2,
            ),
            SizedBox(width: 12),
            // Content column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  SkeletonBox(
                    width: double.infinity * 0.7,
                    height: 14,
                    borderRadius: 4,
                  ),
                  SizedBox(height: 10),
                  // Meta info
                  SkeletonBox(
                    width: double.infinity * 0.55,
                    height: 11,
                    borderRadius: 4,
                  ),
                ],
              ),
            ),
            // Status badge
            SizedBox(width: 12),
            SkeletonBox(
              width: 60,
              height: 22,
              borderRadius: 8,
            ),
          ],
        ),
      ),
    );
  }
}
