import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/transmutation_util.dart';

/// Coloured pill badge showing the DepEd grade descriptor for a given [grade].
///
/// Renders `--` in muted text when [grade] is null.
class DescriptorBadge extends StatelessWidget {
  final int? grade;
  final double height;

  const DescriptorBadge({super.key, required this.grade, this.height = 44});

  @override
  Widget build(BuildContext context) {
    if (grade == null) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            '--',
            style: TextStyle(fontSize: 13, color: AppColors.foregroundLight),
          ),
        ),
      );
    }

    final descriptor = TransmutationUtil.getDescriptor(grade!);
    final colorValue = TransmutationUtil.getDescriptorColor(grade!);

    return SizedBox(
      height: height,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Color(colorValue).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            descriptor,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(colorValue),
            ),
          ),
        ),
      ),
    );
  }
}
