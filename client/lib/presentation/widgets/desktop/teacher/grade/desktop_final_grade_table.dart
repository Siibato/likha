import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/term_utils.dart';
import 'package:likha/presentation/providers/general_average_provider.dart';
import 'package:likha/presentation/widgets/mobile/teacher/grade/descriptor_badge.dart';

/// Desktop final grades table showing T1–T4, Final Grade, General Average,
/// and descriptor badge. Reads [generalAverageProvider] internally.
class DesktopFinalGradeTable extends ConsumerWidget {
  final List<Map<String, dynamic>> finalGrades;

  const DesktopFinalGradeTable({super.key, required this.finalGrades});

  int get _termCount {
    for (final row in finalGrades) {
      for (int i = 4; i >= 1; i--) {
        if (row['t$i'] != null) return i;
      }
    }
    return termCountFromType(null);
  }

  static int? _intOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is num) return v.round();
    return int.tryParse(v.toString());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (finalGrades.isEmpty) {
      return const Center(
        child: Text(
          'No final grades available.',
          style: TextStyle(color: AppColors.foregroundSecondary),
        ),
      );
    }

    final gaState = ref.watch(generalAverageProvider);

    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.backgroundTertiary),
          columnSpacing: 24,
          columns: [
            const DataColumn(
              label: SizedBox(
                width: 160,
                child: Text('Student', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            ...List.generate(_termCount, (i) =>
              DataColumn(label: Text('T${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700)), numeric: true),
            ),
            const DataColumn(label: Text('Final', style: TextStyle(fontWeight: FontWeight.w700)), numeric: true),
            const DataColumn(label: Text('GA', style: TextStyle(fontWeight: FontWeight.w700)), numeric: true),
            const DataColumn(label: Text('Descriptor', style: TextStyle(fontWeight: FontWeight.w700))),
          ],
          rows: List.generate(finalGrades.length, (index) {
            final row = finalGrades[index];
            final termGrades = List.generate(_termCount, (i) => _intOrNull(row['t${i + 1}']))
                .whereType<int>().toList();
            final finalGrade = termGrades.isNotEmpty
                ? (termGrades.reduce((a, b) => a + b) / termGrades.length).round()
                : null;

            final studentId = row['student_id']?.toString();
            int? ga;
            if (gaState.response != null && studentId != null) {
              final match = gaState.response!.students
                  .where((s) => s.studentId == studentId)
                  .toList();
              if (match.isNotEmpty) ga = match.first.generalAverage;
            }

            final isEven = index % 2 == 0;

            return DataRow(
              color: WidgetStateProperty.all(
                isEven ? Colors.white : AppColors.backgroundSecondary,
              ),
              cells: [
                DataCell(SizedBox(
                  width: 160,
                  child: Text(row['student_name']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                )),
                ...List.generate(_termCount, (i) {
                  final grade = _intOrNull(row['t${i + 1}']);
                  return DataCell(Text(grade?.toString() ?? '-', textAlign: TextAlign.right));
                }),
                DataCell(Text(
                  finalGrade?.toString() ?? '-',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: finalGrade != null && finalGrade >= 75
                        ? AppColors.foregroundDark
                        : AppColors.semanticError,
                  ),
                )),
                DataCell(Text(
                  ga?.toString() ?? '-',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                )),
                DataCell(DescriptorBadge(grade: finalGrade)),
              ],
            );
          }),
        ),
      ),
    );
  }
}
