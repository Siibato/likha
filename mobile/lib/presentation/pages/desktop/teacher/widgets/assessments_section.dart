import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/desktop/teacher/create_assessment_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/assessment_detail_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/widgets/assessment_data_table.dart';
import 'package:likha/presentation/pages/desktop/teacher/widgets/empty_state.dart';
import 'package:likha/presentation/providers/teacher_assessment_provider.dart';

/// Assessments section widget for TeacherClassDetailDesktop
/// Displays a list of assessments with create and navigation functionality
class AssessmentsSection extends ConsumerWidget {
  final String classId;

  const AssessmentsSection({
    super.key,
    required this.classId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(teacherAssessmentProvider);

    return DesktopPageScaffold(
      title: 'Assessments',
      actions: [
        FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateAssessmentDesktop(classId: classId),
            ),
          ).then((result) {
            if (result == true) {
              ref
                  .read(teacherAssessmentProvider.notifier)
                  .loadAssessments(classId);
            }
          }),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Create Assessment'),
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
      body: state.isLoading && state.assessments.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  color: AppColors.foregroundPrimary,
                  strokeWidth: 2.5,
                ),
              ),
            )
          : AssessmentDataTable(
              assessments: state.assessments,
              onTap: (assessment) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AssessmentDetailDesktop(assessmentId: assessment.id),
                ),
              ).then((_) => ref
                  .read(teacherAssessmentProvider.notifier)
                  .loadAssessments(classId)),
            ),
    );
  }
}
