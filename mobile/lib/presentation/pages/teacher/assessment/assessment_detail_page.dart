import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/domain/assessments/usecases/update_assessment.dart';
import 'package:likha/presentation/pages/teacher/assessment/assessment_submissions_page.dart';
import 'package:likha/presentation/pages/teacher/assessment/assessment_statistics_page.dart';
import 'package:likha/presentation/pages/teacher/assessment/edit_assessment_page.dart';
import 'package:likha/presentation/pages/teacher/assessment/add_question_page.dart';
import 'package:likha/presentation/pages/teacher/assessment/edit_question_page.dart';
import 'package:likha/presentation/pages/teacher/assessment/widgets/assessment_info_card.dart';
import 'package:likha/presentation/pages/teacher/assessment/widgets/assessment_status_card.dart';
import 'package:likha/presentation/pages/teacher/assessment/widgets/questions_section.dart';
import 'package:likha/presentation/pages/teacher/assessment/widgets/question_reorder_list.dart';
import 'package:likha/presentation/pages/teacher/widgets/reorder_position_dialog.dart';
import 'package:likha/presentation/pages/teacher/widgets/view_tos_chip.dart';
import 'package:likha/presentation/pages/shared/widgets/dialogs/app_dialogs.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/form_message.dart';
import 'package:likha/presentation/pages/teacher/tos/tos_view_page.dart';
import 'package:likha/presentation/providers/teacher_assessment_provider.dart';

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
  String? _formError;
  
  // Grading settings state
  int? _editingGradingPeriod;
  String? _editingComponent;
  bool _isEditingGrading = false;

  @override
  void initState() {
    super.initState();
    _questionAnimController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(teacherAssessmentProvider.notifier)
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
      onConfirm: () => ref.read(teacherAssessmentProvider.notifier).publishAssessment(widget.assessmentId),
    );
  }

  
  void _confirmDelete(Assessment assessment) {
    final hasWarning = assessment.isPublished || assessment.submissionCount > 0;
    final warningBox = hasWarning
        ? Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.semanticErrorBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.semanticError.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_rounded, color: AppColors.semanticError, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    assessment.isPublished
                        ? 'This assessment is published and has ${assessment.submissionCount} submission(s). All data will be lost.'
                        : 'This assessment has ${assessment.submissionCount} submission(s). All data will be lost.',
                    style: const TextStyle(fontSize: 13, color: AppColors.semanticErrorDark),
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
      onConfirm: () => ref.read(teacherAssessmentProvider.notifier).deleteAssessment(widget.assessmentId),
      warningBox: warningBox,
    );
  }

  void _confirmReleaseResults(Assessment assessment) {
    AppDialogs.showConfirmation(
      context: context,
      title: 'Release Results',
      body: 'Release results for "${assessment.title}"? Students will be able to see their scores.',
      confirmLabel: 'Release',
      onConfirm: () => ref.read(teacherAssessmentProvider.notifier).releaseResults(widget.assessmentId),
    );
  }

  void _confirmDeleteQuestion(Question question, bool hasSubmissions) {
    final assessment = ref.read(teacherAssessmentProvider).currentAssessment;
    final warningBox = hasSubmissions && assessment != null
        ? Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentAmberSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accentAmberBorder.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.accentAmber, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This assessment has ${assessment.submissionCount} submission(s). Deleting a question may affect existing scores.',
                    style: const TextStyle(fontSize: 13, color: AppColors.accentAmberBorder),
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
      onConfirm: () => ref.read(teacherAssessmentProvider.notifier).deleteQuestion(question.id),
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
            .read(teacherAssessmentProvider.notifier)
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
    await ref.read(teacherAssessmentProvider.notifier).reorderAllQuestions(
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

  void _startEditingGrading(Assessment assessment) {
    setState(() {
      _editingGradingPeriod = assessment.gradingPeriodNumber;
      _editingComponent = assessment.component;
      _isEditingGrading = true;
    });
  }

  void _cancelEditingGrading() {
    setState(() {
      _editingGradingPeriod = null;
      _editingComponent = null;
      _isEditingGrading = false;
    });
  }

  void _saveGradingSettings() async {
    final assessment = ref.read(teacherAssessmentProvider).currentAssessment;
    if (assessment == null) return;

    setState(() => _isEditingGrading = false);

    try {
      await ref.read(teacherAssessmentProvider.notifier).updateAssessment(
        UpdateAssessmentParams(
          assessmentId: widget.assessmentId,
          gradingPeriodNumber: _editingGradingPeriod,
          component: _editingComponent,
        ),
      );
      
      setState(() {
        _editingGradingPeriod = null;
        _editingComponent = null;
      });
    } catch (e) {
      setState(() => _isEditingGrading = true);
      setState(() => _formError = 'Failed to update grading settings');
    }
  }

  String _getComponentDisplayName(String component) {
    switch (component) {
      case 'written_work':
        return 'Written Work';
      case 'performance_task':
        return 'Performance Task';
      case 'quarterly_assessment':
        return 'Quarterly Assessment';
      default:
        return component;
    }
  }

  @override
  Widget build(BuildContext context) {
    final assessmentState = ref.watch(teacherAssessmentProvider);
    final assessment = assessmentState.currentAssessment;
    final questions = assessmentState.questions;

    ref.listen<TeacherAssessmentState>(teacherAssessmentProvider, (prev, next) {
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        setState(() => _formError = null);
        ref.read(teacherAssessmentProvider.notifier).clearMessages();
        if (next.successMessage == 'Assessment deleted') {
          Navigator.pop(context, true);
        }
        if (next.successMessage == 'Question deleted' ||
            next.successMessage == 'Questions added') {
          ref
              .read(teacherAssessmentProvider.notifier)
              .loadAssessmentDetail(widget.assessmentId);
        }
      }
      if (next.error != null && prev?.error != next.error) {
        setState(() => _formError = AppErrorMapper.toUserMessage(next.error));
        ref.read(teacherAssessmentProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.foregroundPrimary),
        title: Text(
          assessment?.title ?? 'Assessment Detail',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.foregroundPrimary,
            letterSpacing: -0.4,
          ),
        ),
        actions: [],
      ),
      body: assessmentState.isLoading && assessment == null
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.accentCharcoal,
                strokeWidth: 2.5,
              ),
            )
          : assessment == null
              ? const Center(
                  child: Text(
                    'Assessment not found',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.foregroundTertiary,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(teacherAssessmentProvider.notifier)
                      .loadAssessmentDetail(widget.assessmentId),
                  color: AppColors.accentCharcoal,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FormMessage(
                          message: _formError,
                          severity: MessageSeverity.error,
                        ),
                        if (_formError != null) const SizedBox(height: 12),
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
                                          .read(teacherAssessmentProvider.notifier)
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
                        if (assessment.tosId != null) ...[
                          const SizedBox(height: 16),
                          ViewTosChip(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TosViewPage(
                                  tosId: assessment.tosId!,
                                ),
                              ),
                            ),
                          ),
                        ],
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
                                    foregroundColor: AppColors.foregroundPrimary,
                                    elevation: 0,
                                    side: const BorderSide(
                                      color: AppColors.borderLight,
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
                                    foregroundColor: AppColors.foregroundPrimary,
                                    elevation: 0,
                                    side: const BorderSide(
                                      color: AppColors.borderLight,
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
                        // Grading Settings Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Grading Settings',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.foregroundPrimary,
                                    ),
                                  ),
                                  if (!_isEditingGrading)
                                    TextButton.icon(
                                      onPressed: () => _startEditingGrading(assessment),
                                      icon: const Icon(Icons.edit_outlined, size: 16),
                                      label: const Text('Edit'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.foregroundPrimary,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (!_isEditingGrading) ...[
                                Row(
                                  children: [
                                    Icon(
                                      Icons.grain_rounded,
                                      size: 16,
                                      color: assessment.gradingPeriodNumber != null
                                          ? AppColors.foregroundPrimary
                                          : AppColors.foregroundTertiary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      assessment.gradingPeriodNumber != null
                                          ? 'Quarter ${assessment.gradingPeriodNumber}'
                                          : 'No quarter assigned',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: assessment.gradingPeriodNumber != null
                                            ? AppColors.foregroundPrimary
                                            : AppColors.foregroundTertiary,
                                      ),
                                    ),
                                    if (assessment.component != null) ...[
                                      const SizedBox(width: 16),
                                      Icon(
                                        Icons.category_rounded,
                                        size: 16,
                                        color: AppColors.foregroundPrimary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _getComponentDisplayName(assessment.component!),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.foregroundPrimary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ] else ...[
                                // Quarter dropdown
                                DropdownButtonFormField<int?>(
                                  value: _editingGradingPeriod,
                                  decoration: const InputDecoration(
                                    labelText: 'Quarter (for grading)',
                                    labelStyle: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.foregroundTertiary,
                                    ),
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: null, child: Text('None')),
                                    DropdownMenuItem(value: 1, child: Text('Quarter 1')),
                                    DropdownMenuItem(value: 2, child: Text('Quarter 2')),
                                    DropdownMenuItem(value: 3, child: Text('Quarter 3')),
                                    DropdownMenuItem(value: 4, child: Text('Quarter 4')),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _editingGradingPeriod = value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                // Component dropdown
                                DropdownButtonFormField<String?>(
                                  value: _editingComponent,
                                  decoration: const InputDecoration(
                                    labelText: 'Grade Component',
                                    labelStyle: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.foregroundTertiary,
                                    ),
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: null, child: Text('None')),
                                    DropdownMenuItem(value: 'written_work', child: Text('Written Work')),
                                    DropdownMenuItem(value: 'performance_task', child: Text('Performance Task')),
                                    DropdownMenuItem(value: 'quarterly_assessment', child: Text('Quarterly Assessment')),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _editingComponent = value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: _cancelEditingGrading,
                                      child: const Text('Cancel'),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: _saveGradingSettings,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.accentCharcoal,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text('Save Settings'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_isQuestionReorderMode)
                          QuestionReorderList(
                            reorderBuffer: _questionReorderBuffer,
                            questionAnimatingIndices: _questionAnimatingIndices,
                            animationController: _questionAnimController,
                            onShowMoveDialog: _showQuestionMoveDialog,
                            onCancel: _cancelQuestionReorderMode,
                            onConfirm: () => _exitQuestionReorderMode(widget.assessmentId),
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
                                            .read(teacherAssessmentProvider.notifier)
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
                              foregroundColor: AppColors.semanticError,
                              side: const BorderSide(
                                color: AppColors.semanticError,
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
