import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/question_draft.dart';
import 'package:likha/domain/assessments/usecases/add_questions.dart';
import 'package:likha/presentation/layouts/desktop/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/desktop/teacher/assessment/assessment_edit_page.dart';
import 'package:likha/presentation/pages/desktop/teacher/assessment/assessment_submissions_page.dart';
import 'package:likha/presentation/pages/desktop/teacher/assessment/assessment_statistics_page.dart';
import 'package:likha/presentation/providers/assessment/assessment_detail_notifier.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assessment/assessment_action_buttons.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assessment/assessment_detail_actions_menu.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assessment/assessment_info_section.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assessment/assessment_quick_stats.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assessment/assessment_questions_section.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assessment/assessment_status_badge.dart';
import 'package:likha/presentation/widgets/shared/feedback/content_state_builder.dart';
import 'package:likha/presentation/widgets/shared/feedback/provider_message_listener.dart';

class AssessmentDetailPage extends ConsumerStatefulWidget {
  final String assessmentId;

  const AssessmentDetailPage({super.key, required this.assessmentId});

  @override
  ConsumerState<AssessmentDetailPage> createState() =>
      _AssessmentDetailPageState();
}

class _AssessmentDetailPageState
    extends ConsumerState<AssessmentDetailPage> {
  bool _isAddingQuestion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(assessmentDetailProvider.notifier)
          .loadAssessmentDetail(widget.assessmentId);
    });
  }

  Map<String, dynamic> _draftToApiMap(QuestionDraft draft, int orderIndex) {
    final map = <String, dynamic>{
      'question_type': draft.type,
      'question_text': draft.questionText.trim(),
      'points': draft.points,
      'order_index': orderIndex,
    };

    if (draft.type == 'multiple_choice') {
      map['is_multi_select'] = draft.isMultiSelect;
      map['choices'] = draft.choices.asMap().entries.map((ce) {
        return {
          'choice_text': ce.value.text.trim(),
          'is_correct': ce.value.isCorrect,
          'order_index': ce.key,
        };
      }).toList();
    } else if (draft.type == 'identification') {
      map['correct_answers'] = draft.acceptableAnswers
          .where((a) => a.trim().isNotEmpty)
          .map((a) => a.trim())
          .toList();
    } else if (draft.type == 'enumeration') {
      map['enumeration_items'] = draft.enumerationItems.asMap().entries.map((ie) {
        return {
          'order_index': ie.key,
          'acceptable_answers': ie.value.answers
              .where((a) => a.trim().isNotEmpty)
              .map((a) => a.trim())
              .toList(),
        };
      }).toList();
    }

    return map;
  }

  Future<void> _handleAddQuestion(QuestionDraft draft) async {
    final notifier = ref.read(assessmentDetailProvider.notifier);
    final currentQuestions = ref.read(assessmentDetailProvider).questions;
    final orderIndex = currentQuestions.length;

    setState(() => _isAddingQuestion = false);

    await notifier.addQuestions(
      AddQuestionsParams(
        assessmentId: widget.assessmentId,
        questions: [_draftToApiMap(draft, orderIndex)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assessmentDetailProvider);
    final assessment = state.currentAssessment;
    final questions = state.questions;

    return ProviderMessageListener<AssessmentDetailState>(
      provider: assessmentDetailProvider,
      successMessage: (s) => s.successMessage,
      errorMessage: (s) => s.error,
      onClear: () => ref.read(assessmentDetailProvider.notifier).clearMessages(),
      intercept: (prev, next) {
        if (next.successMessage == 'Assessment deleted') {
          Navigator.of(context).pop();
          return true;
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundSecondary,
        body: DesktopPageScaffold(
          title: assessment?.title ?? 'Assessment Detail',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back',
          ),
          actions: [
            if (assessment != null) ...[
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditAssessmentPage(
                        assessment: assessment,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.foregroundDark,
                ),
              ),
              const SizedBox(width: 8),
              AssessmentDetailActionsMenu(
                assessment: assessment,
                assessmentId: widget.assessmentId,
              ),
            ],
          ],
          body: ContentStateBuilder(
            isLoading: state.isLoading && assessment == null,
            error: state.error,
            isEmpty: assessment == null,
            onRetry: () => ref
                .read(assessmentDetailProvider.notifier)
                .loadAssessmentDetail(widget.assessmentId),
            emptyState: const Center(
              child: Text(
                'Assessment not found',
                style: TextStyle(color: AppColors.foregroundTertiary),
              ),
            ),
            child: assessment != null
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AssessmentStatusBadge(assessment: assessment),
                            const SizedBox(height: 24),
                            AssessmentInfoSection(assessment: assessment),
                            const SizedBox(height: 24),
                            AssessmentQuestionsSection(
                              questions: questions,
                              isAddingQuestion: _isAddingQuestion,
                              onOpenAddForm: () =>
                                  setState(() => _isAddingQuestion = true),
                              onCancelAdd: () =>
                                  setState(() => _isAddingQuestion = false),
                              onConfirmAdd: _handleAddQuestion,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AssessmentQuickStats(
                              assessment: assessment,
                              questions: questions,
                            ),
                            const SizedBox(height: 24),
                            AssessmentActionButtons(
                              onViewSubmissions: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AssessmentSubmissionsPage(
                                      assessmentId: widget.assessmentId,
                                    ),
                                  ),
                                );
                              },
                              onViewStatistics: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AssessmentStatisticsPage(
                                      assessmentId: widget.assessmentId,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
