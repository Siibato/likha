import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_text_field.dart';

class AssessmentQuestionInput extends StatelessWidget {
  final StudentQuestion question;
  final Map<String, Set<String>> selectedChoices;
  final TextEditingController? textController;
  final Map<int, TextEditingController>? enumControllers;
  final Function(Set<String>) onChoicesChanged;
  final Function(String) onTextChanged;
  final Function(int, String) onEnumChanged;

  const AssessmentQuestionInput({
    super.key,
    required this.question,
    required this.selectedChoices,
    this.textController,
    this.enumControllers,
    required this.onChoicesChanged,
    required this.onTextChanged,
    required this.onEnumChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (question.questionType) {
      case 'multiple_choice':
        return _MultipleChoiceInput(
          question: question,
          selectedChoices: selectedChoices[question.id] ?? {},
          onChanged: onChoicesChanged,
        );
      case 'identification':
        return _IdentificationInput(
          controller: textController!,
          onChanged: onTextChanged,
        );
      case 'enumeration':
        return _EnumerationInput(
          question: question,
          controllers: enumControllers!,
          onChanged: onEnumChanged,
        );
      case 'essay':
        return _EssayInput(
          controller: textController!,
          onChanged: onTextChanged,
        );
      default:
        return Text('Unknown question type: ${question.questionType}');
    }
  }
}

class _MultipleChoiceInput extends StatefulWidget {
  final StudentQuestion question;
  final Set<String> selectedChoices;
  final Function(Set<String>) onChanged;

  const _MultipleChoiceInput({
    required this.question,
    required this.selectedChoices,
    required this.onChanged,
  });

  @override
  State<_MultipleChoiceInput> createState() => _MultipleChoiceInputState();
}

class _MultipleChoiceInputState extends State<_MultipleChoiceInput> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selectedChoices);
  }

  @override
  Widget build(BuildContext context) {
    final choices = widget.question.choices ?? [];
    final isMultiSelect = widget.question.isMultiSelect;

    if (isMultiSelect) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select all that apply',
            style: TextStyle(fontSize: 12, color: AppColors.foregroundTertiary),
          ),
          const SizedBox(height: 4),
          ...choices.map((choice) => CheckboxListTile(
                title: Text(
                  choice.choiceText,
                  style: const TextStyle(fontSize: 14),
                ),
                value: _selected.contains(choice.id),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selected.add(choice.id);
                    } else {
                      _selected.remove(choice.id);
                    }
                  });
                  widget.onChanged(_selected);
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.accentAmber,
              )),
        ],
      );
    } else {
      final selectedId = _selected.isEmpty ? null : _selected.first;
      return RadioGroup<String>(
        groupValue: selectedId,
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selected = {value};
            });
            widget.onChanged(_selected);
          }
        },
        child: Column(
          children: choices
              .map((choice) => RadioListTile<String>(
                    title: Text(
                      choice.choiceText,
                      style: const TextStyle(fontSize: 14),
                    ),
                    value: choice.id,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: AppColors.accentAmber,
                  ))
              .toList(),
        ),
      );
    }
  }
}

class _IdentificationInput extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;

  const _IdentificationInput({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StyledTextField(
      controller: controller,
      label: 'Answer',
      icon: Icons.edit,
      hintText: 'Type your answer here',
      onChanged: onChanged,
    );
  }
}

class _EssayInput extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;

  const _EssayInput({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Write your essay response below',
          style: TextStyle(fontSize: 12, color: AppColors.foregroundTertiary),
        ),
        const SizedBox(height: 8),
        StyledTextField(
          controller: controller,
          label: 'Essay',
          icon: Icons.description,
          hintText: 'Write your essay here...',
          minLines: 5,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _EnumerationInput extends StatelessWidget {
  final StudentQuestion question;
  final Map<int, TextEditingController> controllers;
  final Function(int, String) onChanged;

  const _EnumerationInput({
    required this.question,
    required this.controllers,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final count = question.enumerationCount ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Provide $count answer${count != 1 ? 's' : ''}',
          style: const TextStyle(fontSize: 12, color: AppColors.foregroundTertiary),
        ),
        const SizedBox(height: 8),
        ...List.generate(count, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: StyledTextField(
              controller: controllers[i] ?? TextEditingController(),
              label: 'Answer ${i + 1}',
              icon: Icons.format_list_numbered,
              hintText: 'Answer ${i + 1}',
              onChanged: (value) => onChanged(i, value),
            ),
          );
        }),
      ],
    );
  }
}