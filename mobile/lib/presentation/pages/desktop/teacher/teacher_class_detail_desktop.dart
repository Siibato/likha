import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_navigation_rail.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/desktop/teacher/class_student_list_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/widgets/assessments_section.dart';
import 'package:likha/presentation/pages/desktop/teacher/assignment/widgets/assignments_section.dart';
import 'package:likha/presentation/pages/desktop/teacher/widgets/class_overview_panel.dart';
import 'package:likha/presentation/pages/desktop/teacher/grade/widgets/grades_section.dart';
import 'package:likha/presentation/pages/desktop/teacher/material/widgets/materials_section.dart';
import 'package:likha/presentation/pages/desktop/teacher/grade/widgets/sf9_section.dart';
import 'package:likha/presentation/pages/desktop/teacher/widgets/student_data_table.dart';
import 'package:likha/presentation/pages/desktop/teacher/widgets/tos_section.dart';
import 'package:likha/presentation/providers/class_provider.dart';
import 'package:likha/presentation/providers/teacher_assessment_provider.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';
import 'package:likha/presentation/providers/learning_material_provider.dart';
import 'package:likha/presentation/providers/tos_provider.dart';
import 'package:likha/presentation/providers/sf9_provider.dart';

class TeacherClassDetailDesktop extends ConsumerStatefulWidget {
  final String classId;

  const TeacherClassDetailDesktop({super.key, required this.classId});

  @override
  ConsumerState<TeacherClassDetailDesktop> createState() =>
      _TeacherClassDetailDesktopState();
}

class _TeacherClassDetailDesktopState
    extends ConsumerState<TeacherClassDetailDesktop> {
  int _selectedIndex = 0;
  final Set<int> _loadedTabs = {0};

  static const _baseSectionTitles = [
    'Overview',
    'Students',
    'Assessments',
    'Assignments',
    'Materials',
    'TOS',
  ];

  static const _baseDestinations = [
    DesktopNavDestination(
      icon: Icons.info_outline_rounded,
      selectedIcon: Icons.info_rounded,
      label: 'Overview',
    ),
    DesktopNavDestination(
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_rounded,
      label: 'Students',
    ),
    DesktopNavDestination(
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment_rounded,
      label: 'Assessments',
    ),
    DesktopNavDestination(
      icon: Icons.task_outlined,
      selectedIcon: Icons.task_rounded,
      label: 'Assignments',
    ),
    DesktopNavDestination(
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book_rounded,
      label: 'Materials',
    ),
    DesktopNavDestination(
      icon: Icons.table_chart_outlined,
      selectedIcon: Icons.table_chart_rounded,
      label: 'TOS',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(classProvider.notifier).loadClassDetail(widget.classId);
    });
  }

  void _onSectionChanged(int index) {
    setState(() => _selectedIndex = index);

    if (_loadedTabs.contains(index)) return;
    _loadedTabs.add(index);

    switch (index) {
      case 2:
        ref
            .read(teacherAssessmentProvider.notifier)
            .loadAssessments(widget.classId);
        break;
      case 3:
        ref
            .read(assignmentProvider.notifier)
            .loadAssignments(widget.classId);
        break;
      case 4:
        ref
            .read(learningMaterialProvider.notifier)
            .loadMaterials(widget.classId);
        break;
      case 5:
        ref.read(tosProvider.notifier).loadTosList(widget.classId);
        break;
      case 6:
        // index 6 is either Grades (non-advisory) or SF9 (advisory)
        final classState = ref.read(classProvider);
        final classEntity = classState.classes.cast<dynamic>().firstWhere(
              (c) => c?.id == widget.classId,
              orElse: () => null,
            );
        final isAdvisory = classEntity?.isAdvisory == true;
        if (isAdvisory) {
          ref.read(sf9Provider.notifier).loadStudents(widget.classId);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final classState = ref.watch(classProvider);
    final detail = classState.currentClassDetail;

    final classEntity = classState.classes.cast<dynamic>().firstWhere(
          (c) => c?.id == widget.classId,
          orElse: () => null,
        );
    final isAdvisory = classEntity?.isAdvisory == true;

    // Build dynamic destinations list
    final lastDestination = isAdvisory
        ? const DesktopNavDestination(
            icon: Icons.grade_outlined,
            selectedIcon: Icons.grade_rounded,
            label: 'SF9',
          )
        : const DesktopNavDestination(
            icon: Icons.grading_outlined,
            selectedIcon: Icons.grading_rounded,
            label: 'Grades',
          );
    final destinations = [..._baseDestinations, lastDestination];

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: Row(
        children: [
          // Left panel
          DesktopNavigationRail(
            selectedIndex: _selectedIndex,
            destinations: destinations,
            onDestinationSelected: _onSectionChanged,
            header: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    color: AppColors.foregroundPrimary,
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Back to classes',
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      detail?.title ?? 'Class',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.foregroundDark,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(
            thickness: 1,
            width: 1,
            color: AppColors.borderLight,
          ),

          // Content area
          Expanded(
            child: detail == null
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.foregroundPrimary,
                      strokeWidth: 2.5,
                    ),
                  )
                : IndexedStack(
                    index: _selectedIndex,
                    children: [
                      // Overview
                      DesktopPageScaffold(
                        title: _baseSectionTitles[0],
                        body: ClassOverviewPanel(
                          detail: detail,
                          classEntity: classEntity,
                          onViewStudents: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ClassStudentListDesktop(
                                  classId: widget.classId),
                            ),
                          ),
                        ),
                      ),

                      // Students
                      DesktopPageScaffold(
                        title: _baseSectionTitles[1],
                        body: StudentDataTable(
                          students: detail.students,
                        ),
                      ),

                      // Assessments
                      AssessmentsSection(classId: widget.classId),

                      // Assignments
                      AssignmentsSection(classId: widget.classId),

                      // Materials
                      MaterialsSection(classId: widget.classId),

                      // TOS
                      TosSection(classId: widget.classId),

                      // Grades (non-advisory) or SF9 (advisory)
                      if (isAdvisory)
                        Sf9Section(classId: widget.classId)
                      else
                        GradesSection(classId: widget.classId),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
