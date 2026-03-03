import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/utils/transmutation_util.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/providers/assessment_provider.dart';
import 'package:likha/presentation/providers/student_class_grades_provider.dart';

class StudentClassGradeDetailPage extends ConsumerStatefulWidget {
  final String classId;
  final String className;
  final ClassGradeData classGrade;

  const StudentClassGradeDetailPage({
    super.key,
    required this.classId,
    required this.className,
    required this.classGrade,
  });

  @override
  ConsumerState<StudentClassGradeDetailPage> createState() =>
      _StudentClassGradeDetailPageState();
}

class _StudentClassGradeDetailPageState
    extends ConsumerState<StudentClassGradeDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(assessmentProvider.notifier)
          .loadAssessments(widget.classId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final assessmentState = ref.watch(assessmentProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClassSectionHeader(
              title: widget.className,
              showBackButton: true,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref
                      .read(assessmentProvider.notifier)
                      .loadAssessments(widget.classId);
                },
                color: const Color(0xFF2B2B2B),
                child: CustomScrollView(
                  slivers: [
                    // Overall grade banner
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: _OverallGradeBanner(
                          reportGrade: widget.classGrade.reportGrade,
                        ),
                      ),
                    ),

                    // Assignments section
                    if (widget.classGrade.assignments.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                          child: Text(
                            'Assignments',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2B2B2B),
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverList.builder(
                          itemCount: widget.classGrade.assignments.length,
                          itemBuilder: (context, index) {
                            final assignment =
                                widget.classGrade.assignments[index];
                            return _AssignmentCard(assignment: assignment);
                          },
                        ),
                      ),
                    ],

                    // Assessments section
                    if (assessmentState.assessments.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                          child: Text(
                            'Assessments',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2B2B2B),
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverList.builder(
                          itemCount: assessmentState.assessments.length,
                          itemBuilder: (context, index) {
                            final assessment =
                                assessmentState.assessments[index];
                            return _AssessmentCard(
                              assessment: assessment,
                              onTap: assessment.resultsReleased
                                  ? () {
                                      // Navigate to assessment result page
                                      // This would navigate to the assessment detail/result page
                                    }
                                  : null,
                            );
                          },
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Assessment scores are shown when released by your teacher',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF999999),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Bottom padding
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 24),
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

class _OverallGradeBanner extends StatelessWidget {
  final int reportGrade;

  const _OverallGradeBanner({required this.reportGrade});

  @override
  Widget build(BuildContext context) {
    final descriptor = TransmutationUtil.getDescriptor(reportGrade);

    return Column(
      children: [
        Text(
          '$reportGrade',
          style: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B2B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          descriptor,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF999999),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Computed from graded assignments',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF999999),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final dynamic assignment;

  const _AssignmentCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final isGraded = assignment.submissionStatus == 'graded' ||
        assignment.submissionStatus == 'returned';
    final score = assignment.score ?? 0;
    final totalPoints = assignment.totalPoints;

    // Compute individual transmuted grade
    final rawScore = (score / totalPoints) * 100;
    final transmutedGrade = TransmutationUtil.transmute(rawScore);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      assignment.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF202020),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (isGraded)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$transmutedGrade',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2B2B2B),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Pending',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (isGraded)
                Row(
                  children: [
                    Text(
                      '$score/$totalPoints',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF999999),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${rawScore.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  'Due: ${_formatDate(assignment.dueAt)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF999999),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final today = DateTime.now();
    final diff = date.difference(DateTime(today.year, today.month, today.day))
        .inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 1) return 'in $diff days';
    return '${diff.abs()} days ago';
  }
}

class _AssessmentCard extends StatelessWidget {
  final dynamic assessment;
  final VoidCallback? onTap;

  const _AssessmentCard({
    required this.assessment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assessment.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF202020),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${assessment.totalPoints} points',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (assessment.resultsReleased)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'View Results',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCCCCC),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Pending',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
