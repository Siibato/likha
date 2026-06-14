import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/domain/assessments/usecases/update_question.dart';
import 'package:likha/presentation/controllers/teacher/assessment/question_form_controller.dart';
import 'package:likha/presentation/providers/teacher_assessment_provider.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/question_form_body.dart';
import 'package:likha/presentation/widgets/shared/cards/question_type_display.dart';

class EditQuestionPage extends ConsumerStatefulWidget {
  final Question question;
  final bool hasSubmissions;
  final String? tosId;
  final List<TosCompetency> tosCompetencies;
  final String classificationMode;

  const EditQuestionPage({
    super.key,
    required this.question,
    required this.hasSubmissions,
    this.tosId,
    this.tosCompetencies = const [],
    this.classificationMode = 'blooms',
  });

  @override
  ConsumerState<EditQuestionPage> createState() => _EditQuestionPageState();
}

class _EditQuestionPageState extends ConsumerState<EditQuestionPage> {
  final _formKey = GlobalKey<FormState>();
  late final QuestionFormController _controller;

  @override
  void initState() {
    super.initState();
    _controller = QuestionFormController.fromQuestion(widget.question);
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

    await ref.read(teacherAssessmentProvider.notifier).updateQuestion(
          UpdateQuestionParams(
            questionId: widget.question.id,
            data: _controller.buildPayload(),
          ),
        );

    if (!mounted) return;
    final state = ref.read(teacherAssessmentProvider);
    if (state.error == null) {
      Navigator.pop(context, true);
    } else {
      _controller.setFormError(AppErrorMapper.toUserMessage(state.error));
      ref.read(teacherAssessmentProvider.notifier).clearMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teacherAssessmentProvider);

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
          'Edit Question',
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
            questionTypeWidget: QuestionTypeDisplay(
              questionType: _controller.questionType,
            ),
            extraLeading: widget.hasSubmissions
                ? [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This assessment has submissions. Changes may affect existing scores.',
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ]
                : const [],
          );
        },
      ),
    );
  }
}
