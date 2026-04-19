import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/presentation/pages/teacher/widgets/student_detail_info_card.dart';
import 'package:likha/presentation/pages/teacher/widgets/student_assessment_row.dart';
import 'package:likha/presentation/pages/teacher/widgets/student_assignment_row.dart';
import 'package:likha/presentation/pages/teacher/submission_review_page.dart';
import 'package:likha/presentation/pages/teacher/assessment_detail_page.dart';
import 'package:likha/presentation/pages/teacher/grade/grade_submission_page.dart';
import 'package:likha/presentation/pages/teacher/assignment/assignment_detail_page.dart';
import 'package:likha/presentation/providers/teacher_student_detail_provider.dart';

enum _ItemType { assessment, assignment }

class _StudentItem {
  final _ItemType type;
  final DateTime dueDate; // closeAt for assessments, dueAt for assignments
  final AssessmentWithStatus? assessmentData;
  final AssignmentWithStatus? assignmentData;

  _StudentItem.assessment(this.assessmentData)
      : type = _ItemType.assessment,
        dueDate = assessmentData!.assessment.closeAt,
        assignmentData = null;

  _StudentItem.assignment(this.assignmentData)
      : type = _ItemType.assignment,
        dueDate = assignmentData!.assignment.dueAt,
        assessmentData = null;
}

class TeacherStudentDetailPage extends ConsumerStatefulWidget {
  final User student;
  final String classId;
  final String classTitle;

  const TeacherStudentDetailPage({
    super.key,
    required this.student,
    required this.classId,
    required this.classTitle,
  });

  @override
  ConsumerState<TeacherStudentDetailPage> createState() =>
      _TeacherStudentDetailPageState();
}

class _TeacherStudentDetailPageState extends ConsumerState<TeacherStudentDetailPage> {
  @override
  void initState() {
    super.initState();
    // Trigger provider initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(teacherStudentDetailProvider(
        (classId: widget.classId, studentId: widget.student.id),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(teacherStudentDetailProvider(
      (classId: widget.classId, studentId: widget.student.id),
    ));

    ref.listen<TeacherStudentDetailState>(
      teacherStudentDetailProvider(
        (classId: widget.classId, studentId: widget.student.id),
      ),
      (prev, next) {
        if (next.error != null && prev?.error != next.error) {
        }
      },
    );

    // Combine and sort by due date descending
    final items = [
      ...detailState.assessments.map((a) => _StudentItem.assessment(a)),
      ...detailState.assignments.map((a) => _StudentItem.assignment(a)),
    ]..sort((a, b) => b.dueDate.compareTo(a.dueDate));

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2B2B2B)),
        title: Text(
          widget.student.fullName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B2B),
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Info Card - with padding
            Padding(
              padding: const EdgeInsets.all(24),
              child: StudentDetailInfoCard(
                student: widget.student,
                classTitle: widget.classTitle,
              ),
            ),

            // Unified Assessments & Assignments Section - full width
            if (detailState.isLoading && items.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                    color: Color(0xFF2B2B2B),
                    strokeWidth: 2.5,
                  ),
                ),
              )
            else if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE0E0E0),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'No assessments or assignments in this class',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: items.map(_buildRow).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(_StudentItem item) {
    if (item.type == _ItemType.assessment) {
      final a = item.assessmentData!;
      return StudentAssessmentRow(
        assessment: a.assessment,
        submission: a.submission,
        onTap: () async {
          if (a.submission != null) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SubmissionReviewPage(submissionId: a.submission!.id),
              ),
            );
          } else {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AssessmentDetailPage(assessmentId: a.assessment.id),
              ),
            );
          }
          if (mounted) {
            ref.read(teacherStudentDetailProvider(
              (classId: widget.classId, studentId: widget.student.id),
            ).notifier).refresh();
          }
        },
      );
    } else {
      final a = item.assignmentData!;
      return StudentAssignmentRow(
        assignment: a.assignment,
        status: a.status,
        onTap: () async {
          if (a.status != null) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GradeSubmissionPage(
                  submissionId: a.status!.submissionId,
                  totalPoints: a.assignment.totalPoints,
                ),
              ),
            );
          } else {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AssignmentDetailPage(assignmentId: a.assignment.id),
              ),
            );
          }
          if (mounted) {
            ref.read(teacherStudentDetailProvider(
              (classId: widget.classId, studentId: widget.student.id),
            ).notifier).refresh();
          }
        },
      );
    }
  }
}
