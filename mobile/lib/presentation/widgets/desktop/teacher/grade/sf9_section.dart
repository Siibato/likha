import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/desktop/teacher/grade/sf9_detail_desktop.dart';
import 'package:likha/presentation/widgets/desktop/teacher/shared/base_data_table.dart';
import 'package:likha/presentation/widgets/desktop/teacher/shared/empty_state.dart';
import 'package:likha/presentation/providers/sf9_provider.dart';

/// SF9 section widget for TeacherClassDetailDesktop
/// Displays SF9 (Form 137) records for advisory classes
class Sf9Section extends ConsumerWidget {
  final String classId;

  const Sf9Section({
    super.key,
    required this.classId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sf9Provider);

    return DesktopPageScaffold(
      title: 'SF9 (Form 137)',
      subtitle: 'Student Academic Records',
      actions: [
        FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Sf9DetailDesktop(
              classId: classId,
              studentId: '', // Will be updated when student is selected
              studentName: '', // Will be updated when student is selected
            ),
            ),
          ).then((_) {
            ref.read(sf9Provider.notifier).loadStudents(classId);
          }),
          icon: const Icon(Icons.file_download_rounded, size: 18),
          label: const Text('Generate SF9'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.foregroundDark,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
      body: state.isLoading && state.students.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  color: AppColors.foregroundPrimary,
                  strokeWidth: 2.5,
                ),
              ),
            )
          : state.students.isEmpty
              ? const EmptyState.generic(
                  title: 'No students enrolled',
                  subtitle: 'No students enrolled in this advisory class',
                )
              : BaseDataTable(
                  items: state.students,
                  columns: const [
                    DataColumn(
                        label: Text('Student Name', style: dataTableHeaderStyle)),
                    DataColumn(
                        label: Text('General Average', style: dataTableHeaderStyle)),
                    DataColumn(
                        label: Text('Subject Count', style: dataTableHeaderStyle)),
                    DataColumn(
                        label: Text('Status', style: dataTableHeaderStyle)),
                  ],
                  rowBuilder: (context, student, index) {
                    return IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              student.studentName,
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
                              student.generalAverage?.toString() ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.foregroundSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              student.subjectCount.toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.foregroundSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: student.generalAverage != null
                                    ? AppColors.semanticSuccessAlt.withValues(alpha: 0.12)
                                    : AppColors.foregroundTertiary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                student.generalAverage != null ? 'Complete' : 'Pending',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: student.generalAverage != null
                                      ? AppColors.semanticSuccessAlt
                                      : AppColors.foregroundTertiary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  onTap: (student) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Sf9DetailDesktop(
                        classId: classId,
                        studentId: student.studentId,
                        studentName: student.studentName,
                      ),
                    ),
                  ),
                ),
    );
  }
}
