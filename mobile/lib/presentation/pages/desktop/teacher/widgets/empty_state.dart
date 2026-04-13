import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// A reusable empty state widget for displaying consistent empty state messages
/// across the desktop interface with customizable icons, text, and actions.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final EdgeInsets? padding;
  final double? iconSize;
  final Color? iconColor;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.padding,
    this.iconSize = 48,
    this.iconColor,
    this.titleStyle,
    this.subtitleStyle,
  });

  /// Creates an empty state for assessments
  const EmptyState.assessments({
    super.key,
    this.action,
    this.padding,
    this.titleStyle,
    this.subtitleStyle,
  }) : icon = Icons.quiz_outlined,
       title = 'No assessments yet',
       subtitle = 'Create your first assessment to get started',
       iconSize = 48,
       iconColor = AppColors.borderLight;

  /// Creates an empty state for assignments
  const EmptyState.assignments({
    super.key,
    this.action,
    this.padding,
    this.titleStyle,
    this.subtitleStyle,
  }) : icon = Icons.assignment_outlined,
       title = 'No assignments yet',
       subtitle = 'Create your first assignment to get started',
       iconSize = 48,
       iconColor = AppColors.borderLight;

  /// Creates an empty state for materials/modules
  const EmptyState.materials({
    super.key,
    this.action,
    this.padding,
    this.titleStyle,
    this.subtitleStyle,
  }) : icon = Icons.library_books_outlined,
       title = 'No modules yet',
       subtitle = 'Create your first learning module',
       iconSize = 48,
       iconColor = AppColors.borderLight;

  /// Creates an empty state for students
  const EmptyState.students({
    super.key,
    this.action,
    this.padding,
    this.titleStyle,
    this.subtitleStyle,
  }) : icon = Icons.people_outline_rounded,
       title = 'No students enrolled',
       subtitle = 'Students will appear here once they join the class',
       iconSize = 48,
       iconColor = AppColors.borderLight;

  /// Creates an empty state for TOS (Table of Specifications)
  const EmptyState.tos({
    super.key,
    this.action,
    this.padding,
    this.titleStyle,
    this.subtitleStyle,
  }) : icon = Icons.table_chart_outlined,
       title = 'No TOS created yet',
       subtitle = 'Create a Table of Specifications for your assessments',
       iconSize = 48,
       iconColor = AppColors.borderLight;

  /// Creates an empty state for classes
  const EmptyState.classes({
    super.key,
    this.action,
    this.padding,
    this.titleStyle,
    this.subtitleStyle,
  }) : icon = Icons.school_outlined,
       title = 'No classes assigned yet',
       subtitle = 'Classes will appear here once you are assigned to teach them',
       iconSize = 48,
       iconColor = AppColors.borderLight;

  /// Creates an empty state for grades
  const EmptyState.grades({
    super.key,
    this.action,
    this.padding,
    this.titleStyle,
    this.subtitleStyle,
  }) : icon = Icons.grading_outlined,
       title = 'No grades available',
       subtitle = 'Grades will appear here once you set up grading and record scores',
       iconSize = 48,
       iconColor = AppColors.borderLight;

  /// Creates a generic empty state with custom message
  const EmptyState.generic({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.padding,
    this.icon = Icons.inbox_outlined,
    this.iconSize = 48,
    this.iconColor = AppColors.borderLight,
    this.titleStyle,
    this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? AppColors.borderLight,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: titleStyle ?? const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.foregroundTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: subtitleStyle ?? const TextStyle(
                  fontSize: 13,
                  color: AppColors.foregroundTertiary,
                ),
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

/// Extension methods for creating common empty state variants
extension EmptyStateExtensions on EmptyState {
  /// Creates an empty state with a create button
  static Widget withCreateButton({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onCreate,
    String createButtonText = 'Create',
    EdgeInsets? padding,
  }) {
    return EmptyState(
      icon: icon,
      title: title,
      subtitle: subtitle,
      padding: padding,
      action: FilledButton.icon(
        onPressed: onCreate,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text(createButtonText),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.foregroundPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }

  /// Creates an empty state for data tables
  static Widget dataTable({
    required String entityName,
    VoidCallback? onCreate,
    String? subtitle,
    EdgeInsets? padding,
  }) {
    IconData icon;
    String title;
    String defaultSubtitle;
    String createButtonText;

    switch (entityName.toLowerCase()) {
      case 'assessment':
        icon = Icons.quiz_outlined;
        title = 'No assessments yet';
        defaultSubtitle = 'Create your first assessment to get started';
        createButtonText = 'Create Assessment';
        break;
      case 'assignment':
        icon = Icons.assignment_outlined;
        title = 'No assignments yet';
        defaultSubtitle = 'Create your first assignment to get started';
        createButtonText = 'Create Assignment';
        break;
      case 'material':
      case 'module':
        icon = Icons.library_books_outlined;
        title = 'No modules yet';
        defaultSubtitle = 'Create your first learning module';
        createButtonText = 'Create Module';
        break;
      case 'student':
        icon = Icons.people_outline_rounded;
        title = 'No students enrolled';
        defaultSubtitle = 'Students will appear here once they join the class';
        createButtonText = 'Add Students';
        break;
      case 'tos':
        icon = Icons.table_chart_outlined;
        title = 'No TOS created yet';
        defaultSubtitle = 'Create a Table of Specifications for your assessments';
        createButtonText = 'Create TOS';
        break;
      case 'class':
        icon = Icons.school_outlined;
        title = 'No classes assigned yet';
        defaultSubtitle = 'Classes will appear here once you are assigned to teach them';
        createButtonText = '';
        break;
      default:
        icon = Icons.inbox_outlined;
        title = 'No $entityName yet';
        defaultSubtitle = 'Create your first $entityName to get started';
        createButtonText = 'Create $entityName';
    }

    if (onCreate != null && createButtonText != null) {
      return withCreateButton(
        icon: icon,
        title: title,
        subtitle: subtitle ?? defaultSubtitle,
        onCreate: onCreate,
        createButtonText: createButtonText,
        padding: padding,
      );
    }

    return EmptyState(
      icon: icon,
      title: title,
      subtitle: subtitle ?? defaultSubtitle,
      padding: padding,
    );
  }
}

/// A loading state widget that matches the empty state styling
class LoadingState extends StatelessWidget {
  final String? message;
  final EdgeInsets? padding;

  const LoadingState({
    super.key,
    this.message,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: AppColors.foregroundPrimary,
              strokeWidth: 2.5,
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.foregroundTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
