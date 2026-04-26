import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/shared/widgets/tokens/app_dimensions.dart';
import 'skeleton_box.dart';

/// Skeleton for BaseCardSm (Pattern A-Small).
///
/// Compact 2-layer shell with placeholder blocks for title and subtitle.
/// Used by teacher/admin list pages with denser card layouts.
class BaseCardSmSkeleton extends StatelessWidget {
  const BaseCardSmSkeleton({super.key});

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
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title shimmer
            SkeletonBox(
              width: double.infinity * 0.75,
              height: 18,
              borderRadius: 4,
            ),
            SizedBox(height: 10),
            // Subtitle shimmer
            SkeletonBox(
              width: double.infinity * 0.55,
              height: 11,
              borderRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}
