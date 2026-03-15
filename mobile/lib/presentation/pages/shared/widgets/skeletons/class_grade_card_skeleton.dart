import 'package:flutter/material.dart';
import 'package:likha/presentation/pages/shared/widgets/tokens/app_dimensions.dart';
import 'skeleton_box.dart';

/// Skeleton for ClassGradeCard.
///
/// Mimics icon slot + class name + grade pill layout.
/// Used by student grades page (inline card skeleton).
class ClassGradeCardSkeleton extends StatelessWidget {
  const ClassGradeCardSkeleton({super.key});

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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon slot
            SkeletonBox(
              width: 36,
              height: 36,
              borderRadius: AppDimensions.kIconSlotRadius,
            ),
            const SizedBox(width: 16),
            // Class name
            Expanded(
              child: SkeletonBox(
                width: double.infinity * 0.6,
                height: 14,
                borderRadius: 4,
              ),
            ),
            // Grade pill
            const SizedBox(width: 12),
            SkeletonBox(
              width: 50,
              height: 22,
              borderRadius: 8,
            ),
          ],
        ),
      ),
    );
  }
}
