import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/presentation/pages/student/take_assessment_page.dart';
import 'package:likha/presentation/pages/student/assessment_results_page.dart';
import 'package:likha/presentation/pages/student/widgets/student_header.dart';
import 'package:likha/presentation/pages/student/widgets/assessment_card.dart';
import 'package:likha/presentation/pages/student/widgets/empty_assessment_state.dart';
import 'package:likha/presentation/providers/assessment_provider.dart';

class AssessmentListPage extends ConsumerStatefulWidget {
  final String classId;

  const AssessmentListPage({super.key, required this.classId});

  @override
  ConsumerState<AssessmentListPage> createState() => _AssessmentListPageState();
}

class _AssessmentListPageState extends ConsumerState<AssessmentListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(assessmentProvider.notifier).loadAssessments(widget.classId);
    });
  }

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

  String _formatTimeLimit(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remaining = minutes % 60;
      if (remaining == 0) {
        return '$hours hr${hours > 1 ? 's' : ''}';
      }
      return '$hours hr${hours > 1 ? 's' : ''} $remaining min';
    }
    return '$minutes min';
  }

  void _onAssessmentTap(Assessment assessment) {
    final status = _getStatus(assessment);
    if (status == AssessmentStatus.available) {
      _confirmStartAssessment(assessment);
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

  void _confirmStartAssessment(Assessment assessment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Start Assessment',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.4,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you ready to start "${assessment.title}"?',
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 16),
            _DialogInfoRow(
              label: 'Time Limit',
              value: _formatTimeLimit(assessment.timeLimitMinutes),
            ),
            const SizedBox(height: 8),
            _DialogInfoRow(
              label: 'Total Points',
              value: '${assessment.totalPoints}',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8ED),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFFBD59).withOpacity(0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: Color(0xFFFFBD59),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Timer starts immediately and cannot be paused',
                      style: TextStyle(
                        color: Color(0xFF2B2B2B),
                        fontSize: 13,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF666666),
            ),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
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
                    .loadAssessments(widget.classId);
              });
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2B2B2B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assessmentProvider);

    ref.listen<AssessmentState>(assessmentProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: const Color(0xFFEA4335),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        ref.read(assessmentProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: state.isLoading && state.assessments.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2B2B2B),
                  strokeWidth: 2.5,
                ),
              )
            : RefreshIndicator(
                onRefresh: () => ref
                    .read(assessmentProvider.notifier)
                    .loadAssessments(widget.classId),
                color: const Color(0xFF2B2B2B),
                child: CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(
                      child: StudentHeader(title: 'Assessments'),
                    ),
                    state.assessments.isEmpty
                        ? const SliverFillRemaining(
                            child: EmptyAssessmentState(),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final assessment = state.assessments[index];
                                  final status = _getStatus(assessment);
                                  return AssessmentCard(
                                    assessment: assessment,
                                    status: status,
                                    onTap: () => _onAssessmentTap(assessment),
                                  );
                                },
                                childCount: state.assessments.length,
                              ),
                            ),
                          ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 40),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _DialogInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _DialogInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
