import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/pages/teacher/add_student_page.dart';
import 'package:likha/presentation/pages/teacher/teacher_assessment_list_page.dart';
import 'package:likha/presentation/pages/teacher/teacher_assignment_list_page.dart';
import 'package:likha/presentation/pages/teacher/teacher_material_list_page.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/pages/shared/class_navigation_card.dart';
import 'package:likha/presentation/providers/class_provider.dart';

class ClassDetailPage extends ConsumerStatefulWidget {
  final String classId;

  const ClassDetailPage({super.key, required this.classId});

  @override
  ConsumerState<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends ConsumerState<ClassDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(classProvider.notifier).loadClassDetail(widget.classId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final classState = ref.watch(classProvider);
    final detail = classState.currentClassDetail;

    ref.listen<ClassState>(classProvider, (prev, next) {
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        ref.read(classProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: null,
      body: detail == null
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2B2B2B),
                strokeWidth: 2.5,
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  ClassSectionHeader(
                    title: detail.title,
                    showBackButton: true,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          ClassNavigationCard(
                            icon: Icons.quiz_outlined,
                            title: 'Assessments',
                            subtitle: 'View and manage quizzes',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TeacherAssessmentListPage(classId: widget.classId),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ClassNavigationCard(
                            icon: Icons.assignment_outlined,
                            title: 'Assignments',
                            subtitle: 'View and manage homework',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TeacherAssignmentListPage(classId: widget.classId),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ClassNavigationCard(
                            icon: Icons.library_books_outlined,
                            title: 'Learning Modules',
                            subtitle: 'Browse class materials',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TeacherMaterialListPage(classId: widget.classId),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ClassNavigationCard(
                            icon: Icons.people_outline_rounded,
                            title: 'Students',
                            subtitle: 'Manage class enrollment',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddStudentPage(classId: widget.classId),
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
