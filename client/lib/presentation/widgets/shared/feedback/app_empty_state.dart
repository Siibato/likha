import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/shared/tokens/app_text_styles.dart';

/// Shared empty state widget for Likha LMS.
///
/// Consolidates the 9+ separate hardcoded empty state widgets scattered across
/// teacher, student, and admin folders into a single configurable component.
///
/// Named constructors provide pre-configured variants for common domains:
/// - [AppEmptyState.assessments]
/// - [AppEmptyState.assignments]
/// - [AppEmptyState.classes]
/// - [AppEmptyState.students]
/// - [AppEmptyState.materials]
/// - [AppEmptyState.grades]
/// - [AppEmptyState.tos]
/// - [AppEmptyState.submissions]
/// - [AppEmptyState.generic] — custom icon + message
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final EdgeInsets? padding;
  final double iconSize;
  final Color? iconColor;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.padding,
    this.iconSize = 52,
    this.iconColor,
  });

  const AppEmptyState.assessments({
    super.key,
    this.action,
    this.padding,
  })  : icon = Icons.quiz_outlined,
        title = 'No assessments yet',
        subtitle = 'Create an assessment to get started',
        iconSize = 52,
        iconColor = null;

  const AppEmptyState.assignments({
    super.key,
    this.action,
    this.padding,
  })  : icon = Icons.assignment_outlined,
        title = 'No assignments yet',
        subtitle = 'Create an assignment to get started',
        iconSize = 52,
        iconColor = null;

  const AppEmptyState.classes({
    super.key,
    this.action,
    this.padding,
  })  : icon = Icons.school_outlined,
        title = 'No classes yet',
        subtitle = 'Classes will appear here once assigned',
        iconSize = 52,
        iconColor = null;

  const AppEmptyState.students({
    super.key,
    this.action,
    this.padding,
  })  : icon = Icons.people_outline_rounded,
        title = 'No students enrolled',
        subtitle = 'Students will appear here once they join the class',
        iconSize = 52,
        iconColor = null;

  const AppEmptyState.materials({
    super.key,
    this.action,
    this.padding,
  })  : icon = Icons.library_books_outlined,
        title = 'No modules yet',
        subtitle = 'Create a learning module to get started',
        iconSize = 52,
        iconColor = null;

  const AppEmptyState.grades({
    super.key,
    this.action,
    this.padding,
  })  : icon = Icons.grading_outlined,
        title = 'No grades available',
        subtitle = 'Grades will appear here once scores are recorded',
        iconSize = 52,
        iconColor = null;

  const AppEmptyState.tos({
    super.key,
    this.action,
    this.padding,
  })  : icon = Icons.table_chart_outlined,
        title = 'No TOS created yet',
        subtitle = 'Create a Table of Specifications for your assessments',
        iconSize = 52,
        iconColor = null;

  const AppEmptyState.submissions({
    super.key,
    this.action,
    this.padding,
  })  : icon = Icons.inbox_outlined,
        title = 'No submissions yet',
        subtitle = 'Submissions will appear here once students respond',
        iconSize = 52,
        iconColor = null;

  const AppEmptyState.generic({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.padding,
    this.icon = Icons.inbox_outlined,
    this.iconSize = 52,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.backgroundTertiary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: iconColor ?? AppColors.foregroundLight,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: AppTextStyles.cardTitleSm.copyWith(
                color: AppColors.foregroundSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: AppTextStyles.cardSubtitleMd,
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
