import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/pages/student/take_assessment_page.dart';
import 'package:likha/presentation/pages/student/assessment_results_page.dart';
import 'package:likha/presentation/pages/student/submit_assignment_page.dart';
import 'package:likha/presentation/pages/student/widgets/assessment_card.dart';
import 'package:likha/presentation/pages/student/widgets/assignment_card.dart';
import 'package:likha/presentation/pages/student/widgets/empty_assessment_state.dart';
import 'package:likha/presentation/pages/student/widgets/empty_assignment_state.dart';
import 'package:likha/presentation/providers/assessment_provider.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';

class StudentClassDetailPage extends ConsumerStatefulWidget {
  final String classId;
  final String classTitle;

  const StudentClassDetailPage({
    super.key,
    required this.classId,
    required this.classTitle,
  });

  @override
  ConsumerState<StudentClassDetailPage> createState() =>
      _StudentClassDetailPageState();
}

class _StudentClassDetailPageState extends ConsumerState<StudentClassDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.classTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B2B),
            letterSpacing: -0.4,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2B2B2B)),
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
                Tab(text: 'Assessments'),
                Tab(text: 'Assignments'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AssessmentTab(classId: widget.classId),
          _AssignmentTab(classId: widget.classId),
        ],
      ),
    );
  }
}

class _AssessmentTab extends ConsumerWidget {
  final String classId;

  const _AssessmentTab({required this.classId});

  AssessmentStatus _getStatus(Assessment assessment) {
    final now = DateTime.now();
    if (assessment.submissionCount > 0) {
      return AssessmentStatus.submitted;
    }
    if (now.isBefore(assessment.openAt)) {
      return AssessmentStatus.notYetOpen;
    }
    if (now.isAfter(assessment.closeAt)) {
      return AssessmentStatus.closed;
    }
    return AssessmentStatus.available;
  }

  void _onAssessmentTap(BuildContext context, WidgetRef ref, Assessment assessment) {
    final status = _getStatus(assessment);
    
    if (status == AssessmentStatus.available) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TakeAssessmentPage(
            assessmentId: assessment.id,
            timeLimitMinutes: assessment.timeLimitMinutes,
          ),
        ),
      ).then((_) {
        ref
            .read(assessmentProvider.notifier)
            .loadAssessments(classId);
      });
    } else if (status == AssessmentStatus.submitted &&
        (assessment.resultsReleased || assessment.showResultsImmediately)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AssessmentResultsPage(assessmentId: assessment.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(assessmentProvider);

    return state.isLoading && state.assessments.isEmpty
        ? const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF2B2B2B),
              strokeWidth: 2.5,
            ),
          )
        : state.assessments.isEmpty
            ? const EmptyAssessmentState()
            : RefreshIndicator(
                onRefresh: () => ref
                    .read(assessmentProvider.notifier)
                    .loadAssessments(classId),
                color: const Color(0xFF2B2B2B),
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: state.assessments.length,
                  itemBuilder: (context, index) {
                    final assessment = state.assessments[index];
                    final status = _getStatus(assessment);
                    return AssessmentCard(
                      assessment: assessment,
                      status: status,
                      onTap: () => _onAssessmentTap(context, ref, assessment),
                    );
                  },
                ),
              );
  }
}

class _AssignmentTab extends ConsumerWidget {
  final String classId;

  const _AssignmentTab({required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(assignmentProvider);

    return state.isLoading && state.assignments.isEmpty
        ? const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF2B2B2B),
              strokeWidth: 2.5,
            ),
          )
        : state.assignments.isEmpty
            ? const EmptyAssignmentState()
            : RefreshIndicator(
                onRefresh: () => ref
                    .read(assignmentProvider.notifier)
                    .loadAssignments(classId),
                color: const Color(0xFF2B2B2B),
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: state.assignments.length,
                  itemBuilder: (context, index) {
                    final assignment = state.assignments[index];
                    final isPastDue =
                        DateTime.now().isAfter(assignment.dueAt);

                    return AssignmentCard(
                      title: assignment.title,
                      totalPoints: assignment.totalPoints,
                      dueAt: assignment.dueAt,
                      isPastDue: isPastDue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SubmitAssignmentPage(
                            assignmentId: assignment.id,
                            assignmentTitle: assignment.title,
                            instructions: assignment.instructions,
                            submissionType: assignment.submissionType,
                            totalPoints: assignment.totalPoints,
                            allowedFileTypes: assignment.allowedFileTypes,
                            maxFileSizeMb: assignment.maxFileSizeMb,
                          ),
                        ),
                      ).then((_) => ref
                          .read(assignmentProvider.notifier)
                          .loadAssignments(classId)),
                    );
                  },
                ),
              );
  }
}