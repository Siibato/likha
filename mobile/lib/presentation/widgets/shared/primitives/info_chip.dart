import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

enum InfoChipVariant { defaultStyle, dark, accent }

/// A small icon + label chip for inline metadata display.
///
/// Default: no background, secondary text/icon.
/// [InfoChip.dark]: charcoal bg, white text.
/// [InfoChip.accent]: amber bg, white text.
class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final InfoChipVariant _variant;

  const InfoChip({
    super.key,
    required this.icon,
    required this.label,
  }) : _variant = InfoChipVariant.defaultStyle;

  const InfoChip._internal({
    super.key,
    required this.icon,
    required this.label,
    required InfoChipVariant variant,
  }) : _variant = variant;

  /// Charcoal bg, white icon and text
  factory InfoChip.dark({
    Key? key,
    required IconData icon,
    required String label,
  }) {
    return InfoChip._internal(
      key: key,
      icon: icon,
      label: label,
      variant: InfoChipVariant.dark,
    );
  }

  /// Amber bg, white icon and text
  factory InfoChip.accent({
    Key? key,
    required IconData icon,
    required String label,
  }) {
    return InfoChip._internal(
      key: key,
      icon: icon,
      label: label,
      variant: InfoChipVariant.accent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final (bgColor, fgColor) = switch (_variant) {
      InfoChipVariant.dark => (AppColors.accentCharcoal, Colors.white),
      InfoChipVariant.accent => (AppColors.accentAmber, Colors.white),
      InfoChipVariant.defaultStyle => (null, AppColors.foregroundSecondary),
    };

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: fgColor),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: fgColor,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );

    if (bgColor == null) return content;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: content,
    );
  }
}
