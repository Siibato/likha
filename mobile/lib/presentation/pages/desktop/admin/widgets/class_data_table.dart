import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import 'base_data_table.dart';
import 'status_badge.dart';
import 'empty_state.dart';
import '../utils/date_utils.dart';

class ClassDataTable extends StatelessWidget {
  final List<ClassEntity> classes;
  final ValueChanged<ClassEntity> onTap;
  final ValueChanged<ClassEntity>? onDelete;
  final int rowsPerPage;

  const ClassDataTable({
    super.key,
    required this.classes,
    required this.onTap,
    this.onDelete,
    this.rowsPerPage = 20,
  });

  @override
  Widget build(BuildContext context) {
    return BaseDataTable<ClassEntity>(
      items: classes,
      columns: [
        DataColumn(
          label: const Text('Class Title', style: dataTableHeaderStyle),
          onSort: (_, __) {},
        ),
        DataColumn(
          label: const Text('Teacher', style: dataTableHeaderStyle),
          onSort: (_, __) {},
        ),
        DataColumn(
          label: const Text('Students', style: dataTableHeaderStyle),
          numeric: true,
          onSort: (_, __) {},
        ),
        const DataColumn(
          label: Text('Advisory', style: dataTableHeaderStyle),
        ),
        const DataColumn(
          label: Text('Status', style: dataTableHeaderStyle),
        ),
        const DataColumn(
          label: Text('Created', style: dataTableHeaderStyle),
        ),
        if (onDelete != null)
          const DataColumn(
            label: Text('', style: dataTableHeaderStyle),
          ),
      ],
      rowBuilder: (context, cls, index) {
        final teacherLabel = cls.teacherFullName.isNotEmpty
            ? cls.teacherFullName
            : cls.teacherUsername;

        return [
          // Class Title
          Text(
            cls.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundDark,
            ),
          ),
          // Teacher
          Text(
            teacherLabel,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.foregroundSecondary,
            ),
          ),
          // Students
          Text(
            '${cls.studentCount}',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.foregroundSecondary,
            ),
          ),
          // Advisory
          cls.isAdvisory
              ? const Icon(Icons.star_rounded,
                  size: 18, color: Color(0xFF4CAF50))
              : const Text(
                  'No',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.foregroundTertiary,
                  ),
                ),
          // Status
          StatusBadge.custom(
            isActive: !cls.isArchived,
            activeText: 'Active',
            inactiveText: 'Archived',
            activeColor: const Color(0xFF28A745),
            inactiveColor: AppColors.foregroundTertiary,
            activeBackgroundColor: const Color(0xFF28A745).withOpacity(0.12),
            inactiveBackgroundColor: AppColors.foregroundTertiary.withOpacity(0.12),
          ),
          // Created date
          Text(
            DesktopDateUtils.formatDateIso(cls.createdAt),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.foregroundTertiary,
            ),
          ),
          // Delete action
          if (onDelete != null)
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFDC3545),
                size: 20,
              ),
              tooltip: 'Delete class',
              onPressed: () => onDelete!(cls),
            ),
        ];
      },
      onTap: onTap,
      rowsPerPage: rowsPerPage,
      emptyState: EmptyState.generic(
        title: 'No classes found',
        subtitle: 'No classes match your search criteria',
        icon: Icons.school_outlined,
      ),
    );
  }
}
