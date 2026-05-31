import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/providers/general_average_provider.dart';
import 'package:likha/presentation/widgets/mobile/teacher/grade/descriptor_badge.dart';
import 'package:likha/presentation/widgets/mobile/teacher/grade/grade_table_cells.dart';

/// Scrollable final grade table showing Q1–Q4, Final Grade, General Average,
/// and descriptor badge for each student.
///
/// Reads [generalAverageProvider] internally for the GA column.
class FinalGradeTable extends ConsumerWidget {
  final List<Map<String, dynamic>> data;

  const FinalGradeTable({super.key, required this.data});

  static int? _intOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is num) return v.round();
    return int.tryParse(v.toString());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const nameWidth = 130.0;
    const cellWidth = 64.0;
    const fgWidth = 80.0;
    const gaWidth = 64.0;
    const descriptorWidth = 130.0;
    const cellHeight = 44.0;

    final gaStudents =
        ref.watch(generalAverageProvider).response?.students ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.backgroundTertiary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    GradeTableCells.headerCell('Student', nameWidth,
                        align: Alignment.centerLeft),
                    GradeTableCells.headerCell('Q1', cellWidth),
                    GradeTableCells.headerCell('Q2', cellWidth),
                    GradeTableCells.headerCell('Q3', cellWidth),
                    GradeTableCells.headerCell('Q4', cellWidth),
                    GradeTableCells.headerCell('Final', fgWidth),
                    GradeTableCells.headerCell('GA', gaWidth),
                    GradeTableCells.headerCell('Descriptor', descriptorWidth),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.borderLight),

              // Data rows
              ...data.asMap().entries.map((entry) {
                final index = entry.key;
                final row = entry.value;
                final studentId = row['student_id'] as String?;
                final studentName = row['student_name'] as String? ?? 'Unknown';

                final q1 = _intOrNull(row['q1']);
                final q2 = _intOrNull(row['q2']);
                final q3 = _intOrNull(row['q3']);
                final q4 = _intOrNull(row['q4']);

                final quarterGrades =
                    [q1, q2, q3, q4].whereType<int>().toList();
                final finalGrade = quarterGrades.isNotEmpty
                    ? (quarterGrades.reduce((a, b) => a + b) /
                            quarterGrades.length)
                        .round()
                    : null;

                final gaMatch = gaStudents.cast<dynamic>().firstWhere(
                      (s) =>
                          s.studentId == studentId ||
                          s.studentName == studentName,
                      orElse: () => null,
                    );
                final ga = gaMatch?.generalAverage as int?;

                return Container(
                  decoration: BoxDecoration(
                    color: index.isEven
                        ? Colors.white
                        : AppColors.backgroundSecondary,
                  ),
                  child: Row(
                    children: [
                      GradeTableCells.dataCell(
                        studentName,
                        nameWidth,
                        cellHeight,
                        align: Alignment.centerLeft,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.foregroundPrimary,
                        ),
                      ),
                      GradeTableCells.dataCell(
                          q1?.toString() ?? '--', cellWidth, cellHeight),
                      GradeTableCells.dataCell(
                          q2?.toString() ?? '--', cellWidth, cellHeight),
                      GradeTableCells.dataCell(
                          q3?.toString() ?? '--', cellWidth, cellHeight),
                      GradeTableCells.dataCell(
                          q4?.toString() ?? '--', cellWidth, cellHeight),
                      GradeTableCells.dataCell(
                        finalGrade?.toString() ?? '--',
                        fgWidth,
                        cellHeight,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: finalGrade != null
                              ? AppColors.foregroundPrimary
                              : AppColors.foregroundLight,
                        ),
                      ),
                      GradeTableCells.dataCell(
                        ga?.toString() ?? '--',
                        gaWidth,
                        cellHeight,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ga != null
                              ? AppColors.foregroundPrimary
                              : AppColors.foregroundLight,
                        ),
                      ),
                      SizedBox(
                        width: descriptorWidth,
                        child:
                            DescriptorBadge(grade: finalGrade, height: cellHeight),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
