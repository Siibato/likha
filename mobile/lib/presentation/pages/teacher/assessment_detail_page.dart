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
import 'package:likha/presentation/pages/teacher/widgets/reorder_position_dialog.dart';
import 'package:likha/presentation/pages/shared/widgets/dialogs/app_dialogs.dart';
import 'package:likha/presentation/providers/assessment_provider.dart';

class AssessmentDetailPage extends ConsumerStatefulWidget {
  final String assessmentId;

  const AssessmentDetailPage({super.key, required this.assessmentId});

  @override
  ConsumerState<AssessmentDetailPage> createState() =>
      _AssessmentDetailPageState();
}

class _AssessmentDetailPageState extends ConsumerState<AssessmentDetailPage>
    with TickerProviderStateMixin {
  bool _isQuestionReorderMode = false;
  List<Question> _questionReorderBuffer = [];
  late AnimationController _questionAnimController;
  final Map<String, int> _questionAnimatingIndices = {};

  @override
  void initState() {
    super.initState();
    _questionAnimController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(assessmentProvider.notifier)
          .loadAssessmentDetail(widget.assessmentId);
    });
  }

  @override
  void dispose() {
    _questionAnimController.dispose();
    super.dispose();
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

  void _enterQuestionReorderMode(List<Question> questions) {
    setState(() {
      _isQuestionReorderMode = true;
      _questionReorderBuffer = List.from(questions);
    });
  }

  void _cancelQuestionReorderMode() {
    setState(() {
      _isQuestionReorderMode = false;
      _questionReorderBuffer = [];
      _questionAnimatingIndices.clear();
    });
  }

  void _exitQuestionReorderMode(String assessmentId) async {
    setState(() {
      _isQuestionReorderMode = false;
      _questionAnimatingIndices.clear();
    });

    final questionIds = _questionReorderBuffer.map((q) => q.id).toList();
    await ref.read(assessmentProvider.notifier).reorderAllQuestions(
      assessmentId: assessmentId,
      questionIds: questionIds,
      orderedQuestions: _questionReorderBuffer,
    );
    _questionReorderBuffer = [];
  }

  void _showQuestionMoveDialog(int index) {
    showDialog(
      context: context,
      builder: (ctx) => ReorderPositionDialog(
        resourceType: 'questions',
        totalCount: _questionReorderBuffer.length,
        currentPosition: index,
        onReorder: (fromIndex, toIndex) {
          _animateQuestionReorder(fromIndex, toIndex);
        },
      ),
    );
  }

  void _animateQuestionReorder(int fromIndex, int toIndex) {
    _questionAnimatingIndices.clear();
    for (int i = 0; i < _questionReorderBuffer.length; i++) {
      _questionAnimatingIndices[_questionReorderBuffer[i].id] = i;
    }

    setState(() {
      final q = _questionReorderBuffer.removeAt(fromIndex);
      _questionReorderBuffer.insert(toIndex, q);
    });

    _questionAnimController.forward(from: 0);
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
                        if (_isQuestionReorderMode)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE0E0E0),
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Questions (${_questionReorderBuffer.length})',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF202020),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: _cancelQuestionReorderMode,
                                      child: const Text('Cancel'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => _exitQuestionReorderMode(widget.assessmentId),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2B2B2B),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Done'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                AnimatedBuilder(
                                  animation: _questionAnimController,
                                  builder: (context, _) => Column(
                                    children: _questionReorderBuffer.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final question = entry.value;
                                      final oldIndex = _questionAnimatingIndices[question.id];
                                      double animOffset = 0;
                                      if (oldIndex != null && oldIndex != index) {
                                        const cardHeight = 92.0;
                                        animOffset = (oldIndex - index) * cardHeight;
                                      }
                                      final currentOffset = Tween<double>(begin: animOffset, end: 0)
                                          .evaluate(_questionAnimController);
                                      return Transform.translate(
                                        key: ValueKey(question.id),
                                        offset: Offset(0, currentOffset),
                                        child: GestureDetector(
                                          onTap: () => _showQuestionMoveDialog(index),
                                          child: Container(
                                            margin: const EdgeInsets.only(bottom: 12),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFAFAFA),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: const Color(0xFFE0E0E0),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 32,
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: const Color(0xFF2B2B2B),
                                                      width: 1.5,
                                                    ),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      '${index + 1}',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w600,
                                                        color: Color(0xFF2B2B2B),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        question.questionText,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w500,
                                                          color: Color(0xFF202020),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Chip(
                                                        label: Text(
                                                          question.questionType,
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                                                        visualDensity: VisualDensity.compact,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons.chevron_right_rounded,
                                                  color: Color(0xFF999999),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
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
                            onEnterReorderMode: !assessment.isPublished && questions.length > 1 && !_isQuestionReorderMode
                                ? () => _enterQuestionReorderMode(questions)
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
