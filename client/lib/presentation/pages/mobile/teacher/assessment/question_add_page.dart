import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/assessments/usecases/add_questions.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/presentation/controllers/teacher/assessment/question_form_controller.dart';
import 'package:likha/presentation/providers/assessment/assessment_detail_notifier.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/question_form_body.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/question_type_dropdown.dart';

class AddQuestionPage extends ConsumerStatefulWidget {
  final String assessmentId;
  final String? tosId;
  final List<TosCompetency> tosCompetencies;
  final String classificationMode;

  const AddQuestionPage({
    super.key,
    required this.assessmentId,
    this.tosId,
    this.tosCompetencies = const [],
    this.classificationMode = 'blooms',
  });

  @override
  ConsumerState<AddQuestionPage> createState() => _AddQuestionPageState();
}

class _AddQuestionPageState extends ConsumerState<AddQuestionPage> {
  final _formKey = GlobalKey<FormState>();
  late final QuestionFormController _controller;

  @override
  void initState() {
    super.initState();
    _controller = QuestionFormController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final error = _controller.validate();
    if (error != null) {
      _controller.setFormError(error);
      return;
    }

    await ref.read(assessmentDetailProvider.notifier).addQuestions(
          AddQuestionsParams(
            assessmentId: widget.assessmentId,
            questions: [_controller.buildAddPayload()],
          ),
        );

    if (!mounted) return;
    final state = ref.read(assessmentDetailProvider);
    if (state.error == null) {
      Navigator.pop(context, true);
    } else {
      _controller.setFormError(AppErrorMapper.toUserMessage(state.error));
      ref.read(assessmentDetailProvider.notifier).clearMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assessmentDetailProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.foregroundPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Question',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.foregroundPrimary,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: state.isLoading ? null : _handleSave,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accentCharcoal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: state.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accentCharcoal,
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return QuestionFormBody(
            controller: _controller,
            formKey: _formKey,
            isLoading: state.isLoading,
            tosId: widget.tosId,
            tosCompetencies: widget.tosCompetencies,
            classificationMode: widget.classificationMode,
            questionTypeWidget: QuestionTypeDropdown(
              value: _controller.questionType,
              onChanged: state.isLoading ? (_) {} : (v) { if (v != null) _controller.setQuestionType(v); },
              enabled: !state.isLoading,
            ),
          );
        },
      ),
    );
  }
}
