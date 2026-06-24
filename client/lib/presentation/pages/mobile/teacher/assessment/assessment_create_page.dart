import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/controllers/teacher/assessment/assessment_create_controller.dart';
import 'package:likha/presentation/providers/assessment/assessment_list_notifier.dart';
import 'package:likha/presentation/providers/assessment/assessment_detail_notifier.dart';
import 'package:likha/presentation/layouts/mobile/mobile_page_scaffold.dart';
import 'package:likha/presentation/providers/tos_provider.dart';
import 'package:likha/presentation/utils/snackbar_utils.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/assessment_create_actions.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/assessment_details_section.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/assessment_draft_banner.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/assessment_questions_section.dart';
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
    _controller = AssessmentCreateController(
      classId: widget.classId,
      listNotifier: ref.read(assessmentListProvider.notifier),
      detailNotifier: ref.read(assessmentDetailProvider.notifier),
    );
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

                FormMessage(
                  message: _controller.formError,
                  severity: MessageSeverity.error,
                ),
                const SizedBox(height: 12),
                AssessmentDetailsSection(
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
                  selectedTerm: _controller.termNumber,
                  selectedComponent: _controller.component,
                  isDepartmentalExam: _controller.isDepartmentalExam,
                  onTermChanged: (v) {
                    _controller.setTermNumber(v);
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
                  onAutoSave: _controller.scheduleAutoSave,
                ),
                const SizedBox(height: 24),
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
                      ? _controller.reorderQuestion
                      : null,
                ),
                const SizedBox(height: 32),

                AssessmentCreateActions(
                  isSaving: _controller.isSaving,
                  isDisabled: _controller.isQuestionReorderMode,
                  onSaveDraft: () async {
                    await _controller.saveDraftWithFeedback();
                    if (!mounted) return;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      context.showSuccessSnackBar('Draft saved', durationMs: 1500);
                    });
                  },
                  onSave: () async {
                    if (!_detailsFormKey.currentState!.validate()) return;
                    final assessment = await _controller.performSave();
                    if (!mounted || assessment == null) return;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      Navigator.pop(context, true);
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
