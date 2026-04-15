import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/logging/page_logger.dart';
import 'package:likha/presentation/pages/teacher/class_student_list.dart';
import 'package:likha/presentation/pages/teacher/teacher_assessment_list_page.dart';
import 'package:likha/presentation/pages/teacher/teacher_assignment_list_page.dart';
import 'package:likha/presentation/pages/teacher/teacher_material_list_page.dart';
import 'package:likha/presentation/pages/teacher/class_record_page.dart';
import 'package:likha/presentation/pages/teacher/sf9_student_list_page.dart';
import 'package:likha/presentation/pages/teacher/tos_list_page.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/navigation_card.dart';
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
                          NavigationCard(
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
                          NavigationCard(
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
                          NavigationCard(
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
                          NavigationCard(
                            icon: Icons.people_outline_rounded,
                            title: 'Students',
                            subtitle: 'View enrolled students',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClassStudentListPage(classId: widget.classId),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          NavigationCard(
                            icon: Icons.grading_outlined,
                            title: 'Grades',
                            subtitle: 'Manage grades and scores',
                            onTap: () {
                              print('*** CLASS DETAIL PAGE: User clicked Grades card, navigating to ClassRecordPage for class: ${widget.classId}');
                              PageLogger.instance.log('User clicked Grades card, navigating to ClassRecordPage for class: ${widget.classId}');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ClassRecordPage(classId: widget.classId),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          NavigationCard(
                            icon: Icons.table_chart_outlined,
                            title: 'Table of Specifications',
                            subtitle: 'Manage TOS and competencies',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TosListPage(classId: widget.classId),
                              ),
                            ),
                          ),
                          // SF9/SF10 card for advisory classes
                          if (classState.classes.any((c) => c.id == widget.classId && c.isAdvisory)) ...[
                            const SizedBox(height: 16),
                            NavigationCard(
                              icon: Icons.assignment_ind_outlined,
                              title: 'SF9 / SF10 Records',
                              subtitle: 'View student report cards',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => Sf9StudentListPage(classId: widget.classId),
                                ),
                              ),
                            ),
                          ],
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
