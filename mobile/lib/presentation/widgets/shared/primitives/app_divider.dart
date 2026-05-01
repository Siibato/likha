import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// Consistent thin divider matching the app design system.
///
/// Replaces inline:
/// ```dart
/// const Divider(height: 1, color: AppColors.borderLight)
/// const VerticalDivider(thickness: 1, width: 1, color: AppColors.borderLight)
/// ```
class AppDivider extends StatelessWidget {
  final double thickness;
  final double? indent;
  final double? endIndent;
  final Color? color;

  const AppDivider({
    super.key,
    this.thickness = 1,
    this.indent,
    this.endIndent,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: thickness,
      thickness: thickness,
      indent: indent,
      endIndent: endIndent,
      color: color ?? AppColors.borderLight,
    );
  }
}

/// Consistent vertical divider matching the app design system.
class AppVerticalDivider extends StatelessWidget {
  final double thickness;
  final double? width;
  final Color? color;

  const AppVerticalDivider({
    super.key,
    this.thickness = 1,
    this.width,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return VerticalDivider(
      thickness: thickness,
      width: width ?? thickness,
      color: color ?? AppColors.borderLight,
    );
  }
}
