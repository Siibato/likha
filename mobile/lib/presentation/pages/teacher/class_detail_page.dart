import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/pages/teacher/add_student_page.dart';
import 'package:likha/presentation/pages/teacher/assessment_detail_page.dart';
import 'package:likha/presentation/pages/teacher/assignment_detail_page.dart';
import 'package:likha/presentation/pages/teacher/create_assessment_page.dart';
import 'package:likha/presentation/pages/teacher/create_assignment_page.dart';
import 'package:likha/presentation/pages/teacher/widgets/empty_assessment_list_state.dart';
import 'package:likha/presentation/pages/teacher/widgets/empty_assignment_list_state.dart';
import 'package:likha/presentation/pages/teacher/widgets/empty_student_state.dart';
import 'package:likha/presentation/pages/teacher/widgets/student_list_item.dart';
import 'package:likha/presentation/pages/teacher/widgets/teacher_assessment_card.dart';
import 'package:likha/presentation/pages/teacher/widgets/teacher_assignment_card.dart';
import 'package:likha/presentation/providers/assessment_provider.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';
import 'package:likha/presentation/providers/class_provider.dart';

class ClassDetailPage extends ConsumerStatefulWidget {
  final String classId;

  const ClassDetailPage({super.key, required this.classId});

  @override
  ConsumerState<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends ConsumerState<ClassDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(classProvider.notifier).loadClassDetail(widget.classId);
      ref.read(assessmentProvider.notifier).loadAssessments(widget.classId);
      ref.read(assignmentProvider.notifier).loadAssignments(widget.classId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classState = ref.watch(classProvider);
    final assessmentState = ref.watch(assessmentProvider);
    final assignmentState = ref.watch(assignmentProvider);
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2B2B2B)),
        title: Text(
          detail?.title ?? 'Class Detail',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B2B),
            letterSpacing: -0.4,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF2B2B2B),
              unselectedLabelColor: const Color(0xFF999999),
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              indicatorColor: const Color(0xFF2B2B2B),
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Students'),
                Tab(text: 'Assessments'),
                Tab(text: 'Assignments'),
              ],
            ),
          ),
        ),
      ),
      body: detail == null
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2B2B2B),
                strokeWidth: 2.5,
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStudentsTab(detail),
                _buildAssessmentsTab(assessmentState),
                _buildAssignmentsTab(assignmentState),
              ],
            ),
    );
  }

  Widget _buildStudentsTab(dynamic detail) {
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(classProvider.notifier).loadClassDetail(widget.classId),
      color: const Color(0xFF2B2B2B),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (detail.description != null && detail.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  detail.description!,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF666666),
                    height: 1.5,
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Students (${detail.students.length})',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202020),
                    letterSpacing: -0.3,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddStudentPage(classId: widget.classId),
                    ),
                  ).then((_) => ref
                      .read(classProvider.notifier)
                      .loadClassDetail(widget.classId)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B2B2B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: const Text(
                    'Add',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (detail.students.isEmpty)
              const EmptyStudentState()
            else
              ...detail.students.map(
                (enrollment) => StudentListItem(
                  studentId: enrollment.student.id,
                  fullName: enrollment.student.fullName,
                  username: enrollment.student.username,
                  onRemove: () => _confirmRemove(
                    context,
                    enrollment.student.id,
                    enrollment.student.fullName,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentsTab(AssessmentState assessmentState) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CreateAssessmentPage(classId: widget.classId),
                  ),
                ).then((result) {
                  if (result == true) {
                    ref
                        .read(assessmentProvider.notifier)
                        .loadAssessments(widget.classId);
                  }
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B2B2B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  'Create',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: assessmentState.isLoading &&
                  assessmentState.assessments.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF2B2B2B),
                    strokeWidth: 2.5,
                  ),
                )
              : assessmentState.assessments.isEmpty
                  ? const EmptyAssessmentListState()
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(assessmentProvider.notifier)
                          .loadAssessments(widget.classId),
                      color: const Color(0xFF2B2B2B),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        itemCount: assessmentState.assessments.length,
                        itemBuilder: (context, index) {
                          final assessment =
                              assessmentState.assessments[index];
                          return TeacherAssessmentCard(
                            assessment: assessment,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AssessmentDetailPage(
                                  assessmentId: assessment.id,
                                ),
                              ),
                            ).then((_) => ref
                                .read(assessmentProvider.notifier)
                                .loadAssessments(widget.classId)),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildAssignmentsTab(AssignmentState assignmentState) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CreateAssignmentPage(classId: widget.classId),
                  ),
                ).then((result) {
                  if (result == true) {
                    ref
                        .read(assignmentProvider.notifier)
                        .loadAssignments(widget.classId);
                  }
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B2B2B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  'Create',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: assignmentState.isLoading &&
                  assignmentState.assignments.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF2B2B2B),
                    strokeWidth: 2.5,
                  ),
                )
              : assignmentState.assignments.isEmpty
                  ? const EmptyAssignmentListState()
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(assignmentProvider.notifier)
                          .loadAssignments(widget.classId),
                      color: const Color(0xFF2B2B2B),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        itemCount: assignmentState.assignments.length,
                        itemBuilder: (context, index) {
                          final assignment =
                              assignmentState.assignments[index];
                          return TeacherAssignmentCard(
                            assignment: assignment,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AssignmentDetailPage(
                                  assignmentId: assignment.id,
                                ),
                              ),
                            ).then((_) => ref
                                .read(assignmentProvider.notifier)
                                .loadAssignments(widget.classId)),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  void _confirmRemove(BuildContext context, String studentId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Remove Student',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Remove $name from this class?',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF666666),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(classProvider.notifier).removeStudent(
                    classId: widget.classId,
                    studentId: studentId,
                  );
            },
            child: const Text(
              'Remove',
              style: TextStyle(
                color: Color(0xFFEF5350),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}