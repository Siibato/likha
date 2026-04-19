import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/desktop/teacher/grade/sf9_detail_desktop.dart';
import 'package:likha/presentation/providers/sf9_provider.dart';

class Sf9StudentListDesktop extends ConsumerStatefulWidget {
  final String classId;

  const Sf9StudentListDesktop({super.key, required this.classId});

  @override
  ConsumerState<Sf9StudentListDesktop> createState() =>
      _Sf9StudentListDesktopState();
}

class _Sf9StudentListDesktopState
    extends ConsumerState<Sf9StudentListDesktop> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sf9Provider.notifier).loadStudents(widget.classId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sf9Provider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: 'Student Records (SF9)',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.foregroundPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        body: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(Sf9State state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.foregroundPrimary,
          strokeWidth: 2.5,
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Text(
          state.error!,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.semanticError,
          ),
        ),
      );
    }

    if (state.students.isEmpty) {
      return const Center(
        child: Text(
          'No students found.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.foregroundSecondary,
          ),
        ),
      );
    }

    return DataTable(
      headingRowColor: WidgetStateProperty.all(AppColors.backgroundTertiary),
      dataRowColor: WidgetStateProperty.all(AppColors.backgroundPrimary),
      columns: const [
        DataColumn(
          label: Text(
            'Student Name',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.foregroundPrimary,
            ),
          ),
        ),
        DataColumn(
          label: Text(
            'General Average',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.foregroundPrimary,
            ),
          ),
          numeric: true,
        ),
        DataColumn(
          label: Text(
            'Subjects',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.foregroundPrimary,
            ),
          ),
          numeric: true,
        ),
      ],
      rows: state.students.map((student) {
        return DataRow(
          onSelectChanged: (_) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Sf9DetailDesktop(
                  classId: widget.classId,
                  studentId: student.studentId,
                  studentName: student.studentName,
                ),
              ),
            );
          },
          cells: [
            DataCell(
              Text(
                student.studentName,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.foregroundPrimary,
                ),
              ),
            ),
            DataCell(
              Text(
                student.generalAverage?.toString() ?? '--',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: student.generalAverage != null
                      ? AppColors.foregroundPrimary
                      : AppColors.foregroundTertiary,
                ),
              ),
            ),
            DataCell(
              Text(
                '${student.subjectCount}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.foregroundSecondary,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
