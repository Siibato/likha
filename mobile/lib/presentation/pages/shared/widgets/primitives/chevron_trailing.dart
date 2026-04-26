import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// A right-pointing chevron icon used as a trailing indicator in cards.
///
/// Provides two size presets: [ChevronTrailing.large] and [ChevronTrailing.small].
class ChevronTrailing extends StatelessWidget {
  final double size;
  final Color color;

  const ChevronTrailing({
    super.key,
    this.size = 24,
    this.color = AppColors.foregroundLight,
  });

  /// Large chevron (size: 24, color: 0xFFCCCCCC)
  factory ChevronTrailing.large({Color? color}) {
    return ChevronTrailing(
      size: 24,
      color: color ?? AppColors.foregroundLight,
    );
  }

  /// Small chevron (size: 22, color: 0xFFE0E0E0)
  factory ChevronTrailing.small({Color? color}) {
    return ChevronTrailing(
      size: 22,
      color: color ?? AppColors.borderLight,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.chevron_right_rounded,
      size: size,
      color: color,
    );
  }
}
