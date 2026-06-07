import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import '../tokens/app_dimensions.dart';

/// A rounded-square icon container used in cards and list items.
///
/// Provides three size presets: [CardIconSlot.sm], [CardIconSlot.md], [CardIconSlot.lg].
/// Uses a background color and renders an icon centered inside.
class CardIconSlot extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final double padding;
  final Color bgColor;
  final Color iconColor;
  final double borderRadius;

  const CardIconSlot({
    super.key,
    required this.icon,
    required this.iconSize,
    required this.padding,
    this.bgColor = AppColors.backgroundTertiary,
    this.iconColor = AppColors.accentCharcoal,
    this.borderRadius = AppDimensions.kIconSlotRadius,
  });

  /// Small icon slot (padding: 8, radius: 10, icon size: 20)
  factory CardIconSlot.sm({
    required IconData icon,
    Color? bgColor,
    Color? iconColor,
  }) {
    return CardIconSlot(
      icon: icon,
      iconSize: AppDimensions.kIconSizeSm,
      padding: AppDimensions.kIconSlotPadSm,
      bgColor: bgColor ?? AppColors.backgroundTertiary,
      iconColor: iconColor ?? AppColors.accentCharcoal,
      borderRadius: AppDimensions.kIconSlotRadiusSm,
    );
  }

  /// Medium icon slot (padding: 10, radius: 12, icon size: 22)
  factory CardIconSlot.md({
    required IconData icon,
    Color? bgColor,
    Color? iconColor,
  }) {
    return CardIconSlot(
      icon: icon,
      iconSize: AppDimensions.kIconSizeMd,
      padding: AppDimensions.kIconSlotPadMd,
      bgColor: bgColor ?? AppColors.backgroundTertiary,
      iconColor: iconColor ?? AppColors.accentCharcoal,
      borderRadius: AppDimensions.kIconSlotRadius,
    );
  }

  /// Large icon slot (padding: 12, radius: 12, icon size: 28)
  factory CardIconSlot.lg({
    required IconData icon,
    Color? bgColor,
    Color? iconColor,
  }) {
    return CardIconSlot(
      icon: icon,
      iconSize: AppDimensions.kIconSizeLg,
      padding: AppDimensions.kIconSlotPadLg,
      bgColor: bgColor ?? AppColors.backgroundTertiary,
      iconColor: iconColor ?? AppColors.accentCharcoal,
      borderRadius: AppDimensions.kIconSlotRadius,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: EdgeInsets.all(padding),
      child: Icon(
        icon,
        size: iconSize,
        color: iconColor,
      ),
    );
  }
}
