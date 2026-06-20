import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/presentation/controllers/teacher/assessment/question_form_controller.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/assessment_field.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/question_editor_body.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/tos_classification_fields.dart';
import 'package:likha/presentation/widgets/shared/forms/form_message.dart';

/// Shared form body for add-question and edit-question flows.
class QuestionFormBody extends StatelessWidget {
  final QuestionFormController controller;
  final GlobalKey<FormState> formKey;
  final bool isLoading;
  final String? tosId;
  final List<TosCompetency> tosCompetencies;
  final String classificationMode;
  final Widget questionTypeWidget;
  final List<Widget> extraLeading;

  const QuestionFormBody({
    super.key,
    required this.controller,
    required this.formKey,
    required this.isLoading,
    this.tosId,
    this.tosCompetencies = const [],
    this.classificationMode = 'blooms',
    required this.questionTypeWidget,
    this.extraLeading = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormMessage(
              message: controller.formError,
              severity: MessageSeverity.error,
            ),
            const SizedBox(height: 16),
            ...extraLeading,
            questionTypeWidget,
            const SizedBox(height: 16),
            AssessmentField(
              label: 'Question Text',
              icon: Icons.help_outline_rounded,
              controller: controller.questionTextController,
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Question text is required';
                }
                return null;
              },
              enabled: !isLoading,
              onChanged: (_) => controller.clearFormError(),
            ),
            const SizedBox(height: 16),
            AssessmentField(
              label: 'Points',
              icon: Icons.star_outline_rounded,
              controller: controller.pointsController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Points are required';
                }
                final points = int.tryParse(value.trim());
                if (points == null || points <= 0) {
                  return 'Enter a valid number of points';
                }
                return null;
              },
              enabled: !isLoading,
              onChanged: (_) => controller.clearFormError(),
            ),
            if (tosId != null && tosCompetencies.isNotEmpty) ...[
              const SizedBox(height: 16),
              TosClassificationFields(
                competencies: tosCompetencies,
                classificationMode: classificationMode,
                selectedCompetencyId: controller.selectedCompetencyId,
                selectedCognitiveLevel: controller.selectedCognitiveLevel,
                onCompetencyChanged: isLoading ? null : controller.setCompetencyId,
                onCognitiveLevelChanged: isLoading ? null : controller.setCognitiveLevel,
                enabled: !isLoading,
              ),
            ],
            const SizedBox(height: 24),
            if (controller.questionType == 'multiple_choice')
              QuestionEditorBody(
                questionType: 'multiple_choice',
                choices: controller.choices,
                isMultiSelect: controller.isMultiSelect,
                isLoading: isLoading,
                variant: EditorStyleVariant.form,
                onMultiSelectChanged: controller.setIsMultiSelect,
                onChoiceCorrectChanged: controller.setChoiceCorrect,
                onChoiceTextChanged: controller.setChoiceText,
                onAddChoice: controller.addChoice,
                onRemoveChoice: controller.removeChoice,
                onStructuralChange: controller.notifyStructuralChange,
              ),
            if (controller.questionType == 'identification')
              QuestionEditorBody(
                questionType: 'identification',
                answerItems: controller.acceptableAnswerControllers,
                isLoading: isLoading,
                variant: EditorStyleVariant.form,
                onAnswerChanged: controller.setAnswerText,
                onAddAnswer: controller.addAnswer,
                onRemoveAnswer: controller.removeAnswer,
                onStructuralChange: controller.notifyStructuralChange,
              ),
            if (controller.questionType == 'enumeration')
              QuestionEditorBody(
                questionType: 'enumeration',
                enumerationItems: controller.enumerationItems,
                isLoading: isLoading,
                variant: EditorStyleVariant.form,
                onEnumAnswerChanged: controller.setEnumAnswerText,
                onAddEnumItem: controller.addEnumItem,
                onRemoveEnumItem: controller.removeEnumItem,
                onAddEnumAnswer: controller.addEnumAnswer,
                onRemoveEnumAnswer: controller.removeEnumAnswer,
                onStructuralChange: controller.notifyStructuralChange,
              ),
            if (controller.questionType == 'essay')
              const QuestionEditorBody(
                questionType: 'essay',
                variant: EditorStyleVariant.form,
              ),
          ],
        ),
      ),
    );
  }
}
