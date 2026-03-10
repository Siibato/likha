import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/utils/snackbar_utils.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/presentation/pages/teacher/assessment_submissions_page.dart';
import 'package:likha/presentation/pages/teacher/assessment_statistics_page.dart';
import 'package:likha/presentation/pages/teacher/edit_assessment_page.dart';
import 'package:likha/presentation/pages/teacher/add_question_page.dart';
import 'package:likha/presentation/pages/teacher/edit_question_page.dart';
import 'package:likha/presentation/pages/teacher/widgets/assessment_info_card.dart';
import 'package:likha/presentation/pages/teacher/widgets/assessment_status_card.dart';
import 'package:likha/presentation/pages/teacher/widgets/questions_section.dart';
import 'package:likha/presentation/pages/shared/widgets/dialogs/app_dialogs.dart';
import 'package:likha/presentation/providers/assessment_provider.dart';

class AssessmentDetailPage extends ConsumerStatefulWidget {
  final String assessmentId;

  const AssessmentDetailPage({super.key, required this.assessmentId});

  @override
  ConsumerState<AssessmentDetailPage> createState() =>
      _AssessmentDetailPageState();
}

class _AssessmentDetailPageState extends ConsumerState<AssessmentDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(assessmentProvider.notifier)
          .loadAssessmentDetail(widget.assessmentId);
    });
  }

  void _confirmPublish(Assessment assessment) {
    AppDialogs.showConfirmation(
      context: context,
      title: 'Publish Assessment',
      body: 'Publish "${assessment.title}"? Once published, questions can no longer be edited.',
      confirmLabel: 'Publish',
      onConfirm: () => ref.read(assessmentProvider.notifier).publishAssessment(widget.assessmentId),
    );
  }

  void _confirmDelete(Assessment assessment) {
    final hasWarning = assessment.isPublished || assessment.submissionCount > 0;
    final warningBox = hasWarning
        ? Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFCDD2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_rounded, color: Color(0xFFEF5350), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    assessment.isPublished
                        ? 'This assessment is published and has ${assessment.submissionCount} submission(s). All data will be lost.'
                        : 'This assessment has ${assessment.submissionCount} submission(s). All data will be lost.',
                    style: const TextStyle(fontSize: 13, color: Color(0xFFC62828)),
                  ),
                ),
              ],
            ),
          )
        : null;

    AppDialogs.showDestructive(
      context: context,
      title: 'Delete Assessment',
      body: 'Delete "${assessment.title}"? This cannot be undone.',
      confirmLabel: 'Delete',
      onConfirm: () => ref.read(assessmentProvider.notifier).deleteAssessment(widget.assessmentId),
      warningBox: warningBox,
    );
  }

  void _confirmReleaseResults(Assessment assessment) {
    AppDialogs.showConfirmation(
      context: context,
      title: 'Release Results',
      body: 'Release results for "${assessment.title}"? Students will be able to see their scores.',
      confirmLabel: 'Release',
      onConfirm: () => ref.read(assessmentProvider.notifier).releaseResults(widget.assessmentId),
    );
  }

  void _confirmDeleteQuestion(Question question, bool hasSubmissions) {
    final assessment = ref.read(assessmentProvider).currentAssessment;
    final warningBox = hasSubmissions && assessment != null
        ? Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFE0B2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFFFFA726), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This assessment has ${assessment.submissionCount} submission(s). Deleting a question may affect existing scores.',
                    style: const TextStyle(fontSize: 13, color: Color(0xFFE65100)),
                  ),
                ),
              ],
            ),
          )
        : null;

    AppDialogs.showDestructive(
      context: context,
      title: 'Delete Question',
      body: 'Delete this question? This cannot be undone.',
      confirmLabel: 'Delete',
      onConfirm: () => ref.read(assessmentProvider.notifier).deleteQuestion(question.id),
      warningBox: warningBox,
    );
  }

  void _navigateToEditQuestion(Question question, bool hasSubmissions) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditQuestionPage(
          question: question,
          hasSubmissions: hasSubmissions,
        ),
      ),
    ).then((result) {
      if (result == true) {
        ref
            .read(assessmentProvider.notifier)
            .loadAssessmentDetail(widget.assessmentId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assessmentProvider);
    final assessment = state.currentAssessment;
    final questions = state.questions;

    ref.listen<AssessmentState>(assessmentProvider, (prev, next) {
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        context.showSuccessSnackBar(next.successMessage!);
        ref.read(assessmentProvider.notifier).clearMessages();
        if (next.successMessage == 'Assessment deleted') {
          Navigator.pop(context, true);
        }
        if (next.successMessage == 'Question deleted' ||
            next.successMessage == 'Questions added') {
          ref
              .read(assessmentProvider.notifier)
              .loadAssessmentDetail(widget.assessmentId);
        }
      }
      if (next.error != null && prev?.error != next.error) {
        context.showErrorSnackBar(next.error!);
        ref.read(assessmentProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2B2B2B)),
        title: Text(
          assessment?.title ?? 'Assessment Detail',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B2B),
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          if (assessment != null) ...[
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditAssessmentPage(
                          assessment: assessment,
                        ),
                      ),
                    ).then((result) {
                      if (result == true) {
                        ref
                            .read(assessmentProvider.notifier)
                            .loadAssessmentDetail(widget.assessmentId);
                      }
                    });
                    break;
                  case 'submissions':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AssessmentSubmissionsPage(
                          assessmentId: widget.assessmentId,
                        ),
                      ),
                    );
                    break;
                  case 'statistics':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AssessmentStatisticsPage(
                          assessmentId: widget.assessmentId,
                        ),
                      ),
                    );
                    break;
                  case 'publish':
                    _confirmPublish(assessment);
                    break;
                  case 'release':
                    _confirmReleaseResults(assessment);
                    break;
                  case 'delete':
                    _confirmDelete(assessment);
                    break;
                }
              },
              itemBuilder: (context) => [
                if (!assessment.isPublished)
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Edit Details'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'submissions',
                  child: Row(
                    children: [
                      Icon(Icons.assignment_turned_in_rounded, size: 20),
                      SizedBox(width: 12),
                      Text('Submissions'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'statistics',
                  child: Row(
                    children: [
                      Icon(Icons.bar_chart_rounded, size: 20),
                      SizedBox(width: 12),
                      Text('Statistics'),
                    ],
                  ),
                ),
                if (!assessment.isPublished)
                  const PopupMenuItem(
                    value: 'publish',
                    child: Row(
                      children: [
                        Icon(Icons.publish_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Publish'),
                      ],
                    ),
                  ),
                if (assessment.isPublished && !assessment.resultsReleased)
                  const PopupMenuItem(
                    value: 'release',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Release Results'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_rounded,
                        color: Color(0xFFEF5350),
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Delete',
                        style: TextStyle(color: Color(0xFFEF5350)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: state.isLoading && assessment == null
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2B2B2B),
                strokeWidth: 2.5,
              ),
            )
          : assessment == null
              ? const Center(
                  child: Text(
                    'Assessment not found',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF999999),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(assessmentProvider.notifier)
                      .loadAssessmentDetail(widget.assessmentId),
                  color: const Color(0xFF2B2B2B),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AssessmentInfoCard(
                          description: assessment.description,
                          timeLimitMinutes: assessment.timeLimitMinutes,
                          totalPoints: assessment.totalPoints,
                          questionCount: assessment.questionCount,
                          submissionCount: assessment.submissionCount,
                          openAt: assessment.openAt,
                          closeAt: assessment.closeAt,
                          showResultsImmediately:
                              assessment.showResultsImmediately,
                          canEdit: !assessment.isPublished,
                          onEdit: !assessment.isPublished
                              ? () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditAssessmentPage(
                                        assessment: assessment,
                                      ),
                                    ),
                                  ).then((result) {
                                    if (result == true) {
                                      ref
                                          .read(assessmentProvider.notifier)
                                          .loadAssessmentDetail(
                                              widget.assessmentId);
                                    }
                                  })
                              : null,
                        ),
                        const SizedBox(height: 16),
                        AssessmentStatusCard(
                          isPublished: assessment.isPublished,
                          resultsReleased: assessment.resultsReleased,
                          onTap: !assessment.isPublished
                              ? () => _confirmPublish(assessment)
                              : assessment.isPublished &&
                                      !assessment.resultsReleased
                                  ? () => _confirmReleaseResults(assessment)
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        if (assessment.isPublished) ...[
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AssessmentSubmissionsPage(
                                        assessmentId: widget.assessmentId,
                                      ),
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF2B2B2B),
                                    elevation: 0,
                                    side: const BorderSide(
                                      color: Color(0xFFE0E0E0),
                                      width: 1,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.assignment_turned_in_rounded,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Submissions',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AssessmentStatisticsPage(
                                        assessmentId: widget.assessmentId,
                                      ),
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF2B2B2B),
                                    elevation: 0,
                                    side: const BorderSide(
                                      color: Color(0xFFE0E0E0),
                                      width: 1,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.bar_chart_rounded,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Statistics',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        QuestionsSection(
                          questions: questions,
                          canEdit: !assessment.isPublished,
                          isPublished: assessment.isPublished,
                          submissionCount: assessment.submissionCount,
                          onAddQuestion: !assessment.isPublished
                              ? () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddQuestionPage(
                                        assessmentId: widget.assessmentId,
                                      ),
                                    ),
                                  ).then((result) {
                                    if (result == true) {
                                      ref
                                          .read(assessmentProvider.notifier)
                                          .loadAssessmentDetail(
                                              widget.assessmentId);
                                    }
                                  })
                              : null,
                          onEditQuestion: !assessment.isPublished
                              ? (question) => _navigateToEditQuestion(
                                    question,
                                    assessment.submissionCount > 0,
                                  )
                              : null,
                          onDeleteQuestion: !assessment.isPublished
                              ? (question) => _confirmDeleteQuestion(
                                    question,
                                    assessment.submissionCount > 0,
                                  )
                              : null,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmDelete(assessment),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFEF5350),
                              side: const BorderSide(
                                color: Color(0xFFEF5350),
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                            ),
                            label: const Text(
                              'Delete Assessment',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
