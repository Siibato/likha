import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// Centralised loading indicator for Likha LMS.
///
/// Replaces the repeated inline [CircularProgressIndicator] pattern:
/// ```dart
/// const Center(child: CircularProgressIndicator(color: AppColors.accentCharcoal, strokeWidth: 2.5))
/// ```
class AppLoader extends StatelessWidget {
  final Color? color;
  final double strokeWidth;
  final double? size;

  const AppLoader({
    super.key,
    this.color,
    this.strokeWidth = 2.5,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final indicator = CircularProgressIndicator(
      color: color ?? AppColors.accentCharcoal,
      strokeWidth: strokeWidth,
    );

    return Center(
      child: size != null
          ? SizedBox(width: size, height: size, child: indicator)
          : indicator,
    );
  }
}
