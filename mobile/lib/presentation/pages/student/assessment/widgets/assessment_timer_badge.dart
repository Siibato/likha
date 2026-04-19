import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/utils/formatters.dart';

class AssessmentTimerBadge extends StatelessWidget {
  final int remainingSeconds;

  const AssessmentTimerBadge({
    super.key,
    required this.remainingSeconds,
  });

  Color _timerColor() {
    if (remainingSeconds <= 60) return const Color(0xFFEA4335);   // red (critical)
    if (remainingSeconds <= 300) return const Color(0xFFFFBD59);  // amber (warning)
    return AppColors.foregroundSecondary;                         // neutral (normal)
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _timerColor().withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _timerColor().withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_rounded,
            size: 18,
            color: _timerColor(),
          ),
          const SizedBox(width: 6),
          Text(
            Formatters.formatTime(remainingSeconds),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: _timerColor(),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}