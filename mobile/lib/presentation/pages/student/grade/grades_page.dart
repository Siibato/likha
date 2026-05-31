import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/pages/student/class/class_grade_detail_page.dart';
import 'package:likha/presentation/widgets/mobile/student/class/class_grade_card.dart';
import 'package:likha/presentation/widgets/mobile/student/grade/empty_grades_state.dart';
import 'package:likha/presentation/widgets/mobile/student/grade/general_average_banner.dart';
import 'package:likha/presentation/providers/student_class_grades_provider.dart';
import 'package:likha/presentation/widgets/shared/feedback/content_state_builder.dart';

class StudentGradesPage extends ConsumerStatefulWidget {
  const StudentGradesPage({super.key});

  @override
  ConsumerState<StudentGradesPage> createState() => _StudentGradesPageState();
}

class _StudentGradesPageState extends ConsumerState<StudentGradesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studentClassGradesProvider.notifier).loadAllClassGrades();
    });
  }

  @override
  Widget build(BuildContext context) {
    final gradesState = ref.watch(studentClassGradesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ClassSectionHeader(
              title: 'My Grades',
              showBackButton: true,
            ),
            Expanded(
              child: ContentStateBuilder(
                isLoading: gradesState.isLoading && gradesState.classGrades.isEmpty,
                isEmpty: gradesState.classGrades.isEmpty,
                onRefresh: () => ref
                    .read(studentClassGradesProvider.notifier)
                    .loadAllClassGrades(),
                onRetry: () => ref
                    .read(studentClassGradesProvider.notifier)
                    .loadAllClassGrades(),
                emptyState: const EmptyGradesState(),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  itemCount: gradesState.classGrades.length +
                      (gradesState.generalAverage != null ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (gradesState.generalAverage != null && index == 0) {
                      return GeneralAverageBanner(
                        average: gradesState.generalAverage!,
                        descriptor: gradesState.generalAverageDescriptor ?? '--',
                      );
                    }
                    final adjustedIndex =
                        gradesState.generalAverage != null ? index - 1 : index;
                    final classGrade = gradesState.classGrades[adjustedIndex];
                    return ClassGradeCard(
                      classGrade: classGrade,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentClassGradeDetailPage(
                            classId: classGrade.classId,
                            className: classGrade.className,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
