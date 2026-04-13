import 'package:flutter/material.dart';

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
          color: Color(0xFF999999),
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
                  ? const Color(0xFFCCCCCC)
                  : const Color(0xFF2B2B2B),
            ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}
