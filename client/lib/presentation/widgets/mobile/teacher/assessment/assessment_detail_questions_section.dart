import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/presentation/controllers/teacher/assessment/assessment_detail_controller.dart';
import 'package:likha/presentation/pages/mobile/teacher/assessment/question_add_page.dart';
import 'package:likha/presentation/pages/mobile/teacher/assessment/question_edit_page.dart';
import 'package:likha/presentation/providers/assessment/assessment_detail_notifier.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/question_reorder_list.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/questions_section.dart';
import 'package:likha/presentation/widgets/mobile/teacher/dashboard/reorder_position_dialog.dart';
import 'package:likha/presentation/widgets/shared/dialogs/app_dialogs.dart';

class AssessmentDetailQuestionsSection extends ConsumerWidget {
  final Assessment assessment;
  final List<Question> questions;
  final AssessmentDetailController controller;
  final AnimationController questionAnimController;
  final String assessmentId;

  const AssessmentDetailQuestionsSection({
    super.key,
    required this.assessment,
    required this.questions,
    required this.controller,
    required this.questionAnimController,
    required this.assessmentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (controller.isQuestionReorderMode) {
      return QuestionReorderList(
        reorderBuffer: controller.questionReorderBuffer,
        questionAnimatingIndices: controller.questionAnimatingIndices,
        animationController: questionAnimController,
        onShowMoveDialog: (index) => _showQuestionMoveDialog(context, index),
        onCancel: controller.cancelQuestionReorderMode,
        onConfirm: () => controller.exitQuestionReorderMode(),
      );
    }

    return QuestionsSection(
      questions: questions,
      canEdit: !assessment.isPublished,
      isPublished: assessment.isPublished,
      submissionCount: assessment.submissionCount,
      onAddQuestion: !assessment.isPublished
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddQuestionPage(
                    assessmentId: assessmentId,
                  ),
                ),
              )
          : null,
      onEditQuestion: !assessment.isPublished
          ? (question) => _navigateToEditQuestion(context, question)
          : null,
      onDeleteQuestion: !assessment.isPublished
          ? (question) => _confirmDeleteQuestion(context, ref, question)
          : null,
      onEnterReorderMode: !assessment.isPublished &&
              questions.length > 1 &&
              !controller.isQuestionReorderMode
          ? () => controller.enterQuestionReorderMode(questions)
          : null,
    );
  }

  void _navigateToEditQuestion(BuildContext context, Question question) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditQuestionPage(
          question: question,
          hasSubmissions: assessment.submissionCount > 0,
        ),
      ),
    );
  }

  void _confirmDeleteQuestion(
    BuildContext context,
    WidgetRef ref,
    Question question,
  ) {
    final hasSubmissions = assessment.submissionCount > 0;
    final warningBox = hasSubmissions
        ? Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentAmberSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.accentAmberBorder.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.accentAmber, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This assessment has ${assessment.submissionCount} submission(s). Deleting a question may affect existing scores.',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.accentAmberBorder),
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
      onConfirm: () => ref
          .read(assessmentDetailProvider.notifier)
          .deleteQuestion(question.id),
      warningBox: warningBox,
    );
  }

  void _showQuestionMoveDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (ctx) => ReorderPositionDialog(
        resourceType: 'questions',
        totalCount: controller.questionReorderBuffer.length,
        currentPosition: index,
        onReorder: (fromIndex, toIndex) {
          controller.animateQuestionReorder(fromIndex, toIndex);
          questionAnimController.forward(from: 0);
        },
      ),
    );
  }
}
