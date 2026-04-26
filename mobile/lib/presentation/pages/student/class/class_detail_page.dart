import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/student/assessment/assessment_list_page.dart';
import 'package:likha/presentation/pages/student/assignment/assignment_list_page.dart';
import 'package:likha/presentation/pages/student/material/material_list_page.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/navigation_card.dart';

class StudentClassDetailPage extends ConsumerWidget {
  final String classId;
  final String classTitle;

  const StudentClassDetailPage({
    super.key,
    required this.classId,
    required this.classTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: null,
      body: SafeArea(
        child: Column(
          children: [
            ClassSectionHeader(title: classTitle, showBackButton: true),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    NavigationCard(
                      icon: Icons.quiz_outlined,
                      title: 'Assessments',
                      subtitle: 'View and manage quizzes',
                      onTap: () =>
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AssessmentListPage(classId: classId),
                            ),
                          ),
                    ),
                    const SizedBox(height: 16),
                    NavigationCard(
                      icon: Icons.assignment_outlined,
                      title: 'Assignments',
                      subtitle: 'View and manage homework',
                      onTap: () =>
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  StudentAssignmentListPage(classId: classId),
                            ),
                          ),
                    ),
                    const SizedBox(height: 16),
                    NavigationCard(
                      icon: Icons.library_books_outlined,
                      title: 'Learning Modules',
                      subtitle: 'Browse class materials',
                      onTap: () =>
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  StudentMaterialListPage(classId: classId),
                            ),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
