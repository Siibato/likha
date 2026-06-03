import 'package:flutter/material.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_button.dart';

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
    return StyledButton(
      text: _label,
      icon: _icon,
      variant: _buttonVariant,
      isLoading: false,
      onPressed: onPressed,
    );
  }

  StyledButtonVariant get _buttonVariant {
    switch (variant) {
      case AssessmentActionVariant.start:
        return StyledButtonVariant.primary;
      case AssessmentActionVariant.resume:
        return StyledButtonVariant.primary;
      case AssessmentActionVariant.viewResults:
        return StyledButtonVariant.outlined;
    }
  }

  String get _label => switch (variant) {
        AssessmentActionVariant.start => 'Start Assessment',
        AssessmentActionVariant.resume => 'Resume Assessment',
        AssessmentActionVariant.viewResults => 'View Full Results',
      };

  IconData get _icon => switch (variant) {
        AssessmentActionVariant.start => Icons.play_arrow_rounded,
        AssessmentActionVariant.resume => Icons.play_circle_rounded,
        AssessmentActionVariant.viewResults => Icons.bar_chart_rounded,
      };
}
