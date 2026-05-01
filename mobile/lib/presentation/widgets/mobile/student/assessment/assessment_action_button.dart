import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// Variant of the assessment CTA button.
enum AssessmentActionVariant { start, resume, viewResults }

/// Full-width CTA button for the student assessment detail page.
///
/// Renders colour, icon, and label based on [variant]:
/// - [AssessmentActionVariant.start] — green "Start Assessment"
/// - [AssessmentActionVariant.resume] — amber "Resume Assessment"
/// - [AssessmentActionVariant.viewResults] — charcoal "View Full Results"
class AssessmentActionButton extends StatelessWidget {
  final AssessmentActionVariant variant;
  final VoidCallback onPressed;

  const AssessmentActionButton({
    super.key,
    required this.variant,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _backgroundColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_icon, size: 20, color: _iconColor),
            const SizedBox(width: 8),
            Text(
              _label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color get _backgroundColor => switch (variant) {
        AssessmentActionVariant.start => AppColors.semanticSuccessAlt,
        AssessmentActionVariant.resume => AppColors.accentAmber,
        AssessmentActionVariant.viewResults => AppColors.accentCharcoal,
      };

  IconData get _icon => switch (variant) {
        AssessmentActionVariant.start => Icons.play_arrow_rounded,
        AssessmentActionVariant.resume => Icons.play_circle_rounded,
        AssessmentActionVariant.viewResults => Icons.bar_chart_rounded,
      };

  Color get _iconColor => switch (variant) {
        AssessmentActionVariant.start => Colors.white,
        AssessmentActionVariant.resume => AppColors.accentCharcoal,
        AssessmentActionVariant.viewResults => Colors.white,
      };

  Color get _labelColor => switch (variant) {
        AssessmentActionVariant.start => Colors.white,
        AssessmentActionVariant.resume => AppColors.accentCharcoal,
        AssessmentActionVariant.viewResults => Colors.white,
      };

  String get _label => switch (variant) {
        AssessmentActionVariant.start => 'Start Assessment',
        AssessmentActionVariant.resume => 'Resume Assessment',
        AssessmentActionVariant.viewResults => 'View Full Results',
      };
}
