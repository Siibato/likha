import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/desktop/teacher/assessment_detail_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/assignment_detail_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/class_student_list_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/create_assessment_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/create_assignment_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/create_material_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/material_detail_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/widgets/assessment_data_table.dart';
import 'package:likha/presentation/pages/desktop/teacher/widgets/assignment_data_table.dart';
import 'package:likha/presentation/pages/desktop/teacher/widgets/class_overview_panel.dart';
import 'package:likha/presentation/pages/desktop/teacher/widgets/material_data_table.dart';
import 'package:likha/presentation/pages/desktop/teacher/widgets/student_data_table.dart';
import 'package:likha/presentation/pages/teacher/class_grading_setup_page.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';
import 'package:likha/presentation/providers/class_provider.dart';
import 'package:likha/presentation/providers/learning_material_provider.dart';
import 'package:likha/presentation/providers/teacher_assessment_provider.dart';

class TeacherClassDetailDesktop extends ConsumerStatefulWidget {
  final String classId;

  const TeacherClassDetailDesktop({super.key, required this.classId});

  @override
  ConsumerState<TeacherClassDetailDesktop> createState() =>
      _TeacherClassDetailDesktopState();
}

class _TeacherClassDetailDesktopState
    extends ConsumerState<TeacherClassDetailDesktop>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<int> _loadedTabs = {0};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(classProvider.notifier).loadClassDetail(widget.classId);
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final index = _tabController.index;
    if (_loadedTabs.contains(index)) return;
    _loadedTabs.add(index);

    switch (index) {
      case 2: // Assessments
        ref
            .read(teacherAssessmentProvider.notifier)
            .loadAssessments(widget.classId);
        break;
      case 3: // Assignments
        ref
            .read(assignmentProvider.notifier)
            .loadAssignments(widget.classId);
        break;
      case 4: // Materials
        ref
            .read(learningMaterialProvider.notifier)
            .loadMaterials(widget.classId);
        break;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classState = ref.watch(classProvider);
    final detail = classState.currentClassDetail;

    final classEntity = classState.classes.cast<dynamic>().firstWhere(
          (c) => c?.id == widget.classId,
          orElse: () => null,
        );

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: detail?.title ?? 'Class Detail',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.foregroundPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        body: detail == null
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.foregroundPrimary,
                  strokeWidth: 2.5,
                ),
              )
            : Column(
                children: [
                  // Tab bar
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: AppColors.borderLight),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.foregroundPrimary,
                      unselectedLabelColor: AppColors.foregroundTertiary,
                      indicatorColor: AppColors.foregroundPrimary,
                      indicatorWeight: 2.5,
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Students'),
                        Tab(text: 'Assessments'),
                        Tab(text: 'Assignments'),
                        Tab(text: 'Materials'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Overview tab
                        SingleChildScrollView(
                          child: ClassOverviewPanel(
                            detail: detail,
                            classEntity: classEntity,
                            onViewStudents: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClassStudentListDesktop(
                                    classId: widget.classId),
                              ),
                            ),
                            onGradingSetup: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClassGradingSetupPage(
                                    classId: widget.classId),
                              ),
                            ),
                          ),
                        ),

                        // Students tab
                        SingleChildScrollView(
                          child: StudentDataTable(
                            students: detail.students,
                          ),
                        ),

                        // Assessments tab
                        _AssessmentsTab(classId: widget.classId),

                        // Assignments tab
                        _AssignmentsTab(classId: widget.classId),

                        // Materials tab
                        _MaterialsTab(classId: widget.classId),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _AssessmentsTab extends ConsumerWidget {
  final String classId;

  const _AssessmentsTab({required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(teacherAssessmentProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CreateAssessmentDesktop(classId: classId),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.isLoading && state.assessments.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  color: AppColors.foregroundPrimary,
                  strokeWidth: 2.5,
                ),
              ),
            )
          else
            AssessmentDataTable(
              assessments: state.assessments,
              onTap: (assessment) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AssessmentDetailDesktop(
                      assessmentId: assessment.id),
                ),
              ).then((_) => ref
                  .read(teacherAssessmentProvider.notifier)
                  .loadAssessments(classId)),
            ),
        ],
      ),
    );
  }
}

class _AssignmentsTab extends ConsumerWidget {
  final String classId;

  const _AssignmentsTab({required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(assignmentProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CreateAssignmentDesktop(classId: classId),
                  ),
                ).then((result) {
                  if (result == true) {
                    ref
                        .read(assignmentProvider.notifier)
                        .loadAssignments(classId);
                  }
                }),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Create Assignment'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.foregroundDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.isLoading && state.assignments.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  color: AppColors.foregroundPrimary,
                  strokeWidth: 2.5,
                ),
              ),
            )
          else
            AssignmentDataTable(
              assignments: state.assignments,
              onTap: (assignment) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AssignmentDetailDesktop(
                      assignmentId: assignment.id),
                ),
              ).then((_) => ref
                  .read(assignmentProvider.notifier)
                  .loadAssignments(classId)),
            ),
        ],
      ),
    );
  }
}

class _MaterialsTab extends ConsumerWidget {
  final String classId;

  const _MaterialsTab({required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(learningMaterialProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CreateMaterialDesktop(classId: classId),
                  ),
                ).then((result) {
                  if (result == true) {
                    ref
                        .read(learningMaterialProvider.notifier)
                        .loadMaterials(classId);
                  }
                }),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Create Module'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.foregroundDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.isLoading && state.materials.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  color: AppColors.foregroundPrimary,
                  strokeWidth: 2.5,
                ),
              ),
            )
          else
            MaterialDataTable(
              materials: state.materials,
              onTap: (material) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MaterialDetailDesktop(materialId: material.id),
                ),
              ).then((_) => ref
                  .read(learningMaterialProvider.notifier)
                  .loadMaterials(classId)),
            ),
        ],
      ),
    );
  }
}
