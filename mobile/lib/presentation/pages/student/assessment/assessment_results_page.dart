import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/pages/student/assessment/widgets/score_summary_card.dart';
import 'package:likha/presentation/pages/student/assessment/widgets/answer_result_card.dart';
import 'package:likha/presentation/providers/student_assessment_provider.dart';
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
            .read(studentAssessmentProvider.notifier)
            .loadStudentResults(widget.submissionId!);
      } else if (widget.assessmentId != null) {
        _loadViaAssessment();
      }
    });
  }

  Future<void> _loadViaAssessment() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    await ref
        .read(studentAssessmentProvider.notifier)
        .loadStudentResultsByAssessment(widget.assessmentId!, user.id);
  }

  Widget _buildResultsNotReleasedBox() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.hourglass_bottom_rounded,
                size: 24,
                color: AppColors.foregroundTertiary,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Results Pending',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentCharcoal,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Your teacher hasn\'t released results yet',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.foregroundSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsUnavailableBox() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.semanticError.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                size: 24,
                color: AppColors.semanticError,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Results Not Yet Available',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentCharcoal,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Your results will appear here once your teacher releases them',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.foregroundSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentAssessmentProvider);
    final result = state.studentResult;
    final isResultsNotReleased =
        state.error?.toLowerCase().contains('not been released') ?? false;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: SafeArea(
        child: state.isLoading && result == null && !isResultsNotReleased
            ? Center(
                child: state.error != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.semanticError.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(
                              Icons.error_outline_rounded,
                              size: 64,
                              color: AppColors.semanticError,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              state.error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.semanticError,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: () => Navigator.pop(context),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accentCharcoal,
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
                        color: AppColors.accentCharcoal,
                        strokeWidth: 2.5,
                      ),
              )
            : CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: ClassSectionHeader(
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
                        if (isResultsNotReleased) _buildResultsNotReleasedBox(),
                        if (result != null) ...[
                          ScoreSummaryCard(result: result),
                          const SizedBox(height: 32),
                          const Text(
                            'Question Breakdown',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentCharcoal,
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
                        ],
                        if (result == null && !isResultsNotReleased) _buildResultsUnavailableBox(),
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