import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/pages/student/widgets/student_header.dart';
import 'package:likha/presentation/pages/student/widgets/score_summary_card.dart';
import 'package:likha/presentation/pages/student/widgets/answer_result_card.dart';
import 'package:likha/presentation/providers/assessment_provider.dart';
import 'package:likha/presentation/providers/auth_provider.dart';

class AssessmentResultsPage extends ConsumerStatefulWidget {
  final String? submissionId;
  final String? assessmentId;

  const AssessmentResultsPage({
    super.key,
    this.submissionId,
    this.assessmentId,
  }) : assert(
          submissionId != null || assessmentId != null,
          'Either submissionId or assessmentId must be provided',
        );

  @override
  ConsumerState<AssessmentResultsPage> createState() =>
      _AssessmentResultsPageState();
}

class _AssessmentResultsPageState
    extends ConsumerState<AssessmentResultsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.submissionId != null) {
        ref
            .read(assessmentProvider.notifier)
            .loadStudentResults(widget.submissionId!);
      } else if (widget.assessmentId != null) {
        _loadViaAssessment();
      }
    });
  }

  Future<void> _loadViaAssessment() async {
    final user = ref.read(authProvider).user;

    await ref
        .read(assessmentProvider.notifier)
        .startAssessment(
          widget.assessmentId!,
          user?.id       ?? '',
          user?.fullName ?? '',
          user?.username ?? '',
        );
    final state = ref.read(assessmentProvider);
    if (state.startResult != null) {
      ref
          .read(assessmentProvider.notifier)
          .loadStudentResults(state.startResult!.submissionId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assessmentProvider);
    final result = state.studentResult;

    ref.listen<AssessmentState>(assessmentProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: const Color(0xFFEA4335),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        ref.read(assessmentProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: state.isLoading || result == null
            ? Center(
                child: state.error != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEEBEE),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(
                              Icons.error_outline_rounded,
                              size: 64,
                              color: Color(0xFFEA4335),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              state.error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFEA4335),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: () => Navigator.pop(context),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2B2B2B),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Go Back'),
                          ),
                        ],
                      )
                    : const CircularProgressIndicator(
                        color: Color(0xFF2B2B2B),
                        strokeWidth: 2.5,
                      ),
              )
            : CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: StudentHeader(
                      title: 'Results',
                      showBackButton: true,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        ScoreSummaryCard(result: result),
                        const SizedBox(height: 32),
                        const Text(
                          'Question Breakdown',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2B2B2B),
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...result.answers.asMap().entries.map(
                              (entry) => AnswerResultCard(
                                answer: entry.value,
                                questionNumber: entry.key + 1,
                              ),
                            ),
                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}