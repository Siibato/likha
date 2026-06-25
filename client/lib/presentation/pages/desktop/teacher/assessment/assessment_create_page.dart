import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/presentation/controllers/teacher/assessment/assessment_create_controller.dart';
import 'package:likha/presentation/providers/assessment/assessment_list_notifier.dart';
import 'package:likha/presentation/providers/assessment/assessment_detail_notifier.dart';
import 'package:likha/presentation/layouts/desktop/desktop_page_scaffold.dart';
import 'package:likha/presentation/providers/tos_provider.dart';
import 'package:likha/presentation/utils/snackbar_utils.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assessment/assessment_create_actions.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assessment/assessment_draft_resume_banner.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assessment/assessment_questions_panel.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assessment/assessment_settings_panel.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assessment/tos_progress_tracker.dart';
import 'package:likha/presentation/widgets/shared/forms/form_message.dart';

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

  Future<void> _handleSave(TableOfSpecifications? linkedTos, List<TosCompetency> competencies) async {
    if (!_detailsFormKey.currentState!.validate()) return;

    if (linkedTos != null) {
      final summary = _controller.computeTosProgress(linkedTos, competencies: competencies);
      if (!summary.isComplete) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('TOS Targets Not Met'),
            content: const Text(
              "You haven't fulfilled all TOS level targets yet. Save anyway?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Go Back'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentCharcoal,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save Anyway'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
      }
    }

    final assessment = await _controller.performSave();
    if (!mounted || assessment == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pop(context, true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tosState = ref.watch(tosProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final TableOfSpecifications? linkedTos = _controller.linkedTosId != null
              ? tosState.tosList.where((t) => t.id == _controller.linkedTosId).firstOrNull
              : null;

          final competencies = (linkedTos != null && tosState.currentTos?.id == linkedTos.id)
              ? tosState.competencies
              : <TosCompetency>[];

          final tosSummary = linkedTos != null
              ? _controller.computeTosProgress(linkedTos, competencies: competencies)
              : null;

          return DesktopPageScaffold(
            title: 'Create Assessment',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Back',
            ),
            actions: [
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
                onSave: () => _handleSave(linkedTos, competencies),
              ),
            ],
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_controller.draftLoaded)
                  AssessmentDraftResumeBanner(
                      onDiscard: _controller.discardDraft),
                FormMessage(
                  message: _controller.formError,
                  severity: MessageSeverity.error,
                ),
                if (linkedTos != null && tosSummary != null)
                  TosProgressTracker(
                    tos: linkedTos,
                    summary: tosSummary,
                    competencies: competencies,
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AssessmentSettingsPanel(
                        formKey: _detailsFormKey,
                        titleCtrl: _controller.titleController,
                        descriptionCtrl: _controller.descriptionController,
                        timeLimitCtrl: _controller.timeLimitController,
                        openAt: _controller.openAt,
                        closeAt: _controller.closeAt,
                        showResultsImmediately:
                            _controller.showResultsImmediately,
                        isPublished: _controller.isPublished,
                        termNumber: _controller.termNumber,
                        component: _controller.component,
                        isDepartmentalExam:
                            _controller.isDepartmentalExam,
                        linkedTosId: _controller.linkedTosId,
                        isSaving: _controller.isSaving,
                        tosList: tosState.tosList,
                        onOpenAtChanged: (dt) {
                          _controller.setOpenAt(dt);
                          _controller.scheduleAutoSave();
                        },
                        onCloseAtChanged: (dt) {
                          _controller.setCloseAt(dt);
                          _controller.scheduleAutoSave();
                        },
                        onShowResultsChanged: (v) {
                          _controller.setShowResultsImmediately(v);
                          _controller.scheduleAutoSave();
                        },
                        onPublishChanged: (v) {
                          _controller.setIsPublished(v);
                          _controller.scheduleAutoSave();
                        },
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
                        onLinkedTosChanged: (v) {
                          _controller.setLinkedTosId(v);
                          _controller.scheduleAutoSave();
                          if (v != null) {
                            ref.read(tosProvider.notifier).loadTosDetail(v);
                          }
                        },
                        onAutoSave: _controller.scheduleAutoSave,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: AssessmentQuestionsPanel(
                        questions: _controller.questions,
                        isAddingQuestion: _controller.isAddingQuestion,
                        isReorderMode: _controller.isQuestionReorderMode,
                        isSaving: _controller.isSaving,
                        editingQuestionIndex:
                            _controller.editingQuestionIndex,
                        linkedTos: linkedTos,
                        tosCompetencies: competencies,
                        onEnterReorderMode:
                            _controller.enterQuestionReorderMode,
                        onExitReorderMode:
                            _controller.exitQuestionReorderMode,
                        onOpenAddForm: () =>
                            _controller.setIsAddingQuestion(true),
                        onCancelAdd: () =>
                            _controller.setIsAddingQuestion(false),
                        onEditQuestion: (i) =>
                            _controller.setEditingQuestionIndex(i),
                        onDeleteQuestion: _controller.removeQuestion,
                        onReorderQuestion: _controller.reorderQuestion,
                        onConfirmAdd: _controller.confirmAddQuestion,
                        onSaveEdit: _controller.saveEdit,
                        onCancelEdit: () =>
                            _controller.setEditingQuestionIndex(null),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
