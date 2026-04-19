import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/info_panel.dart';
import 'package:likha/presentation/pages/shared/widgets/primitives/info_row.dart';
import 'package:likha/presentation/pages/shared/widgets/tokens/app_text_styles.dart';
import 'status_badge.dart';
import 'empty_state.dart';
import '../utils/date_utils.dart';

/// A reusable class information panel widget
/// that displays class details with consistent styling.
class ClassInfoPanel extends StatelessWidget {
  final ClassDetail detail;
  final ClassEntity? classInfo;
  final String teacherName;
  final VoidCallback? onEdit;
  final bool showEditButton;

  const ClassInfoPanel({
    super.key,
    required this.detail,
    this.classInfo,
    required this.teacherName,
    this.onEdit,
    this.showEditButton = true,
  });

  /// Creates a class info panel with automatic teacher name resolution
  factory ClassInfoPanel.withClassInfo({
    required ClassDetail detail,
    required ClassEntity classInfo,
    VoidCallback? onEdit,
    bool showEditButton = true,
  }) {
    final teacherName = classInfo.teacherFullName.isNotEmpty
        ? classInfo.teacherFullName
        : classInfo.teacherUsername;

    return ClassInfoPanel(
      detail: detail,
      classInfo: classInfo,
      teacherName: teacherName,
      onEdit: onEdit,
      showEditButton: showEditButton,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdvisory = detail.isAdvisory == true || (classInfo?.isAdvisory == true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Class Info Panel
        InfoPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(detail.title, style: AppTextStyles.cardTitleLg),
              if (detail.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  detail.description!,
                  style: AppTextStyles.cardSubtitleMd,
                ),
              ],
              const SizedBox(height: 16),
              // Two-column layout for class info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InfoRow(label: 'Teacher', value: teacherName),
                        if (classInfo?.teacherUsername?.isNotEmpty == true) ...[
                          const SizedBox(height: 12),
                          InfoRow(
                            label: 'Username',
                            value: classInfo!.teacherUsername!,
                          ),
                        ],
                        const SizedBox(height: 12),
                        InfoRow(
                          label: 'Advisory',
                          valueWidget: isAdvisory
                              ? const UnconstrainedBox(
                                  alignment: Alignment.centerLeft,
                                  child: _AdvisoryBadge(),
                                )
                              : const Text(
                                  'No',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.foregroundSecondary,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 12),
                        InfoRow(
                          label: 'Students',
                          value: '${classInfo?.studentCount ?? 0}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  // Right column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InfoRow(
                          label: 'Status',
                          valueWidget: UnconstrainedBox(
                            alignment: Alignment.centerLeft,
                            child: _ClassStatusBadge(
                              isArchived: classInfo?.isArchived ?? false,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        InfoRow(
                          label: 'Created',
                          value: DesktopDateUtils.formatDate(detail.createdAt),
                        ),
                        if (detail.updatedAt != null) ...[
                          const SizedBox(height: 12),
                          InfoRow(
                            label: 'Last Updated',
                            value: DesktopDateUtils.formatDate(detail.updatedAt!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Edit button
        if (showEditButton && classInfo != null) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text('Edit Class'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.foregroundPrimary,
                side: const BorderSide(color: AppColors.borderLight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A widget for displaying the advisory class badge
class _AdvisoryBadge extends StatelessWidget {
  const _AdvisoryBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.3),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 16, color: Color(0xFF4CAF50)),
          SizedBox(width: 4),
          Text(
            'Advisory Class',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }
}

/// A widget for displaying class status badge
class _ClassStatusBadge extends StatelessWidget {
  final bool isArchived;

  const _ClassStatusBadge({
    required this.isArchived,
  });

  @override
  Widget build(BuildContext context) {
    return StatusBadge.custom(
      isActive: !isArchived,
      activeText: 'Active',
      inactiveText: 'Archived',
      activeColor: const Color(0xFF28A745),
      inactiveColor: AppColors.foregroundTertiary,
      activeBackgroundColor: const Color(0xFF28A745).withOpacity(0.12),
      inactiveBackgroundColor: AppColors.foregroundTertiary.withOpacity(0.12),
    );
  }
}

/// A compact class overview card for dashboard use
class ClassOverviewCard extends StatelessWidget {
  final ClassEntity classEntity;
  final VoidCallback? onTap;
  final double? width;

  const ClassOverviewCard({
    super.key,
    required this.classEntity,
    this.onTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      classEntity.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foregroundPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (classEntity.isAdvisory)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                classEntity.teacherFullName.isNotEmpty
                    ? classEntity.teacherFullName
                    : classEntity.teacherUsername,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.foregroundSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _ClassStatusBadge(isArchived: classEntity.isArchived),
                  const Spacer(),
                  Text(
                    '${classEntity.studentCount} students',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.foregroundTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A grid of class overview cards
class ClassOverviewGrid extends StatelessWidget {
  final List<ClassEntity> classes;
  final ValueChanged<ClassEntity>? onTap;
  final int crossAxisCount;
  final double childAspectRatio;
  final double spacing;

  const ClassOverviewGrid({
    super.key,
    required this.classes,
    this.onTap,
    this.crossAxisCount = 3,
    this.childAspectRatio = 1.2,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (classes.isEmpty) {
      return EmptyState.generic(
        title: 'No classes found',
        subtitle: 'No classes are available',
        icon: Icons.school_outlined,
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final classEntity = classes[index];
        return ClassOverviewCard(
          classEntity: classEntity,
          onTap: onTap != null ? () => onTap!(classEntity) : null,
        );
      },
    );
  }
}
