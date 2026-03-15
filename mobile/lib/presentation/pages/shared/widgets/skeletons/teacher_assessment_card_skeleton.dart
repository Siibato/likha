import 'package:flutter/material.dart';
import 'package:likha/presentation/pages/shared/widgets/tokens/app_dimensions.dart';
import 'skeleton_box.dart';

/// Skeleton for TeacherAssessmentCard.
///
/// Mimics BaseCardSm shape: icon + title + metadata.
/// Used by teacher assessment list page.
class TeacherAssessmentCardSkeleton extends StatelessWidget {
  const TeacherAssessmentCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.kCardSmListSpacing),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
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
            // Icon slot
            SkeletonBox(
              width: 36,
              height: 36,
              borderRadius: 10,
            ),
            const SizedBox(width: 14),
            // Text column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  SkeletonBox(
                    width: double.infinity * 0.65,
                    height: 14,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 8),
                  // Metadata
                  SkeletonBox(
                    width: double.infinity * 0.5,
                    height: 11,
                    borderRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
