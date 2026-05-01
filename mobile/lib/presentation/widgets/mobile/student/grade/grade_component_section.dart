import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/mobile/student/grade/grade_item_models.dart';

/// Card showing all grade items for one grading component (WW, PT, or QA).
class GradeComponentSection extends StatelessWidget {
  final String title;
  final String component;
  final double weight;
  final List<GradeItemDetail> items;

  const GradeComponentSection({
    super.key,
    required this.title,
    required this.component,
    required this.weight,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final componentItems = items.where((i) => i.component == component).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.foregroundDark,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundTertiary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${weight.toInt()}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foregroundSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              if (componentItems.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.borderLight),
                const SizedBox(height: 8),
                ...componentItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.foregroundSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item.effectiveScore != null
                              ? '${formatGradeNum(item.effectiveScore!)}/${formatGradeNum(item.totalPoints)}'
                              : '--/${formatGradeNum(item.totalPoints)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentCharcoal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: AppColors.borderLight),
                const SizedBox(height: 8),
              ] else ...[
                const SizedBox(height: 12),
                const Text(
                  'No items yet',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.foregroundTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              // Percentage/weighted rows are not available in the current schema
              // but the layout is preserved for future use.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Percentage: --',
                    style: TextStyle(fontSize: 12, color: AppColors.foregroundTertiary),
                  ),
                  Text(
                    'Weighted: --',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foregroundSecondary,
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
