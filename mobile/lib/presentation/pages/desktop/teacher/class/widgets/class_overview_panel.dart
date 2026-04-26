import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/info_panel.dart';
import 'package:likha/presentation/pages/shared/widgets/primitives/info_row.dart';
import 'package:likha/presentation/pages/shared/widgets/tokens/app_text_styles.dart';

class ClassOverviewPanel extends StatelessWidget {
  final ClassDetail detail;
  final ClassEntity? classEntity;
  final VoidCallback? onViewStudents;
  final VoidCallback? onGradingSetup;

  const ClassOverviewPanel({
    super.key,
    required this.detail,
    this.classEntity,
    this.onViewStudents,
    this.onGradingSetup,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(detail.title, style: AppTextStyles.cardTitleLg),
              if (detail.description != null) ...[
                const SizedBox(height: 8),
                Text(detail.description!, style: AppTextStyles.cardSubtitleMd),
              ],
              const SizedBox(height: 16),
              InfoRow(
                label: 'Students',
                value: '${detail.students.length}',
              ),
              const SizedBox(height: 12),
              InfoRow(
                label: 'Created',
                value: _formatDate(detail.createdAt),
              ),
              if (classEntity != null && classEntity!.isAdvisory) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.semanticSuccessAlt.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.semanticSuccessAlt.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded,
                          size: 16, color: AppColors.semanticSuccessAlt),
                      SizedBox(width: 4),
                      Text(
                        'Advisory Class',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.semanticSuccessAlt,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Quick actions
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (onViewStudents != null)
              _ActionChip(
                icon: Icons.people_outline_rounded,
                label: 'View Students',
                onTap: onViewStudents!,
              ),
            if (onGradingSetup != null)
              _ActionChip(
                icon: Icons.settings_outlined,
                label: 'Grading Setup',
                onTap: onGradingSetup!,
              ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppColors.foregroundPrimary),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.foregroundPrimary,
        ),
      ),
      onPressed: onTap,
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppColors.borderLight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
