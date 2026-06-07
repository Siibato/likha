import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/learning_materials/entities/learning_material.dart';
import 'package:likha/presentation/widgets/desktop/teacher/shared/base_data_table.dart';
import 'package:likha/presentation/widgets/desktop/teacher/shared/empty_state.dart';

class MaterialDataTable extends StatelessWidget {
  final List<LearningMaterial> materials;
  final ValueChanged<LearningMaterial> onTap;
  final int rowsPerPage;

  const MaterialDataTable({
    super.key,
    required this.materials,
    required this.onTap,
    this.rowsPerPage = 20,
  });

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return BaseDataTable<LearningMaterial>(
      items: materials,
      rowsPerPage: rowsPerPage,
      emptyState: const EmptyState.materials(),
      columnFlexes: const [3, 1, 1, 1],
      columns: [
        DataColumn(
          label: const Text('Title', style: dataTableHeaderStyle),
          onSort: (_, __) {}, // Sorting handled by BaseDataTable
        ),
        const DataColumn(
          label: Text('Files', style: dataTableHeaderStyle),
          numeric: true,
        ),
        const DataColumn(
          label: Text('Created', style: dataTableHeaderStyle),
        ),
        const DataColumn(
          label: Text('Updated', style: dataTableHeaderStyle),
        ),
      ],
      rowBuilder: (context, material, index) {
        return IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  material.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foregroundDark,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '${material.fileCount}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.foregroundSecondary,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  _formatDate(material.createdAt),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.foregroundTertiary,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  _formatDate(material.updatedAt),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.foregroundTertiary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      onTap: onTap,
    );
  }
}
