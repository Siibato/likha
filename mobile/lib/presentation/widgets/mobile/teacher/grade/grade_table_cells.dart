import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

class GradeTableCells {
  static Widget headerCell(
    String text,
    double width, {
    Alignment align = Alignment.center,
  }) {
    return Container(
      width: width,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: align,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.foregroundTertiary,
          letterSpacing: 0.3,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  static Widget dataCell(
    String text,
    double width,
    double height, {
    Alignment align = Alignment.center,
    TextStyle? style,
  }) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: align,
      child: Text(
        text,
        style: style ??
            TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: text == '--'
                  ? AppColors.foregroundLight
                  : AppColors.accentCharcoal,
            ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}
