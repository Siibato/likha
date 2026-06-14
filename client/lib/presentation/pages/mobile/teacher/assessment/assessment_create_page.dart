import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/controllers/teacher/assessment/assessment_create_controller.dart';
import 'package:likha/presentation/layouts/mobile/mobile_page_scaffold.dart';
import 'package:likha/presentation/providers/tos_provider.dart';
import 'package:likha/presentation/utils/snackbar_utils.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/assessment_details_section.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/assessment_draft_banner.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/assessment_questions_section.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/assessment_save_button.dart';
import 'package:likha/presentation/widgets/shared/dialogs/move_question_dialog.dart';
import 'package:likha/presentation/widgets/shared/forms/form_message.dart';
import 'package:likha/presentation/widgets/shared/primitives/class_section_header.dart';

class CreateAssessmentPage extends ConsumerStatefulWidget {
  final String classId;

  const CreateAssessmentPage({super.key, required this.classId});

  @override
  ConsumerState<CreateAssessmentPage> createState() =>
      _CreateAssessmentPageState();
}

class _CreateAssessmentPageState extends ConsumerState<CreateAssessmentPage> {
  final _detailsFormKey = GlobalKey<FormState>();
  late final AssessmentCreateController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AssessmentCreateController(classId: widget.classId);
    _controller.init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tosProvider.notifier).loadTosList(widget.classId);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_detailsFormKey.currentState!.validate()) return;

    final assessment = await _controller.performSave(ref);
    if (assessment != null && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _handleSaveDraft() async {
    await _controller.saveDraftWithFeedback();
    if (mounted) {
      context.showSuccessSnackBar('Draft saved', durationMs: 1500);
    }
  }

  void _showQuestionMoveDialog(int currentIndex) {
    showDialog(
      context: context,
      builder: (_) => MoveQuestionDialog(
        currentIndex: currentIndex,
        questionCount: _controller.questions.length,
        onMove: _controller.reorderQuestion,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return MobilePageScaffold(
          title: 'Create Assessment',
          scrollable: true,
          header: const ClassSectionHeader(
            title: 'Create Assessment',
            showBackButton: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_controller.draftLoaded)
                  AssessmentDraftBanner(onDiscard: _controller.discardDraft),

                const Text(
                  'Assessment Details',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foregroundPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                FormMessage(
                  message: _controller.formError,
                  severity: MessageSeverity.error,
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: AssessmentDetailsSection(
                    formKey: _detailsFormKey,
                    titleController: _controller.titleController,
                    descriptionController: _controller.descriptionController,
                    timeLimitController: _controller.timeLimitController,
                    openAt: _controller.openAt,
                    closeAt: _controller.closeAt,
                    showResultsImmediately: _controller.showResultsImmediately,
                    isPublished: _controller.isPublished,
                    isLoading: _controller.isSaving,
                    onOpenAtChanged: (dt) {
                      _controller.setOpenAt(dt);
                      _controller.scheduleAutoSave();
                    },
                    onCloseAtChanged: (dt) {
                      _controller.setCloseAt(dt);
                      _controller.scheduleAutoSave();
                    },
                    onShowResultsChanged: (value) {
                      _controller.setShowResultsImmediately(value);
                      _controller.scheduleAutoSave();
                    },
                    onIsPublishedChanged: (value) {
                      _controller.setIsPublished(value);
                      _controller.scheduleAutoSave();
                    },
                    selectedQuarter: _controller.quarter,
                    selectedComponent: _controller.component,
                    isDepartmentalExam: _controller.isDepartmentalExam,
                    onQuarterChanged: (v) {
                      _controller.setQuarter(v);
                      _controller.scheduleAutoSave();
                    },
                    onComponentChanged: (v) {
                      _controller.setComponent(v);
                      _controller.scheduleAutoSave();
                    },
                    onDepartmentalExamChanged: (v) {
                      _controller.setIsDepartmentalExam(v);
                      _controller.scheduleAutoSave();
                    },
                    selectedTosId: _controller.linkedTosId,
                    tosList: ref.watch(tosProvider).tosList,
                    onTosChanged: (v) {
                      _controller.setLinkedTosId(v);
                      _controller.scheduleAutoSave();
                    },
                    onCreateAssessment: null,
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Questions (${_controller.questions.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foregroundPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                AssessmentQuestionsSection(
                  questions: _controller.questions,
                  isLoading: _controller.isSaving,
                  isReorderMode: _controller.isQuestionReorderMode,
                  onAddQuestion: _controller.isQuestionReorderMode
                      ? null
                      : _controller.addQuestion,
                  onRemoveQuestion: _controller.removeQuestion,
                  onQuestionsChanged: _controller.scheduleAutoSave,
                  onSaveQuestions: null,
                  onEnterReorderMode:
                      _controller.questions.length > 1 &&
                              !_controller.isQuestionReorderMode
                          ? _controller.enterQuestionReorderMode
                          : null,
                  onExitReorderMode: _controller.isQuestionReorderMode
                      ? _controller.exitQuestionReorderMode
                      : null,
                  onReorderQuestion: _controller.isQuestionReorderMode
                      ? _showQuestionMoveDialog
                      : null,
                ),
                const SizedBox(height: 32),

                Row(
                  children: [
                    OutlinedButton(
                      onPressed: _controller.isSaving ? null : _handleSaveDraft,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentCharcoal,
                        side: const BorderSide(color: AppColors.borderLight),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        disabledForegroundColor: AppColors.foregroundLight,
                      ),
                      child: const Text(
                        'Save Draft',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AssessmentSaveButton(
                        isSaving: _controller.isSaving,
                        isDisabled: _controller.isQuestionReorderMode,
                        onSave: _handleSave,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
