import 'package:flutter/material.dart';
import 'package:likha/presentation/pages/shared/widgets/tokens/app_dimensions.dart';
import 'skeleton_box.dart';

/// Skeleton for BaseCard (Pattern A).
///
/// Mimics the 2-layer shell design with placeholder blocks for title and subtitle.
/// Used by various list pages that need generic card-shaped skeletons.
class BaseCardSkeleton extends StatelessWidget {
  const BaseCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.kCardListSpacing),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title shimmer
            SkeletonBox(
              width: double.infinity * 0.8,
              height: 20,
              borderRadius: 4,
            ),
            const SizedBox(height: 12),
            // Subtitle shimmer
            SkeletonBox(
              width: double.infinity * 0.6,
              height: 12,
              borderRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}
