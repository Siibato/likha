import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// A pulsing grey placeholder cell shown in the grade spreadsheet while
/// scores are being fetched or auto-generated. Uses Flutter's built-in
/// [AnimationController] — no extra packages required.
class GradeSkeletonCell extends StatefulWidget {
  final double width;
  final double height;

  const GradeSkeletonCell({
    super.key,
    required this.width,
    required this.height,
  });

  @override
  State<GradeSkeletonCell> createState() => _GradeSkeletonCellState();
}

class _GradeSkeletonCellState extends State<GradeSkeletonCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Color?> _color;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _color = ColorTween(
      begin: AppColors.borderLight,
      end: AppColors.backgroundTertiary,
    ).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _color,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        alignment: Alignment.center,
        color: Colors.transparent,
        child: Container(
          width: widget.width * 0.65,
          height: 10,
          decoration: BoxDecoration(
            color: _color.value,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
