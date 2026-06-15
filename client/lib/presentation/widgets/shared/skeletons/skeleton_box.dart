import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// Reusable placeholder box for skeleton screens.
/// A simple gray container used as shimmer blocks inside skeleton cards.
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.color = AppColors.backgroundTertiary,
    this.borderRadius = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
