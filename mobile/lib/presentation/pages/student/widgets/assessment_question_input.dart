import 'package:flutter/material.dart';
import 'package:likha/domain/assessments/entities/question.dart';

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
            style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
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
                activeColor: const Color(0xFFFFBD59),
              )),
        ],
      );
    } else {
      final selectedId = _selected.isEmpty ? null : _selected.first;
      return Column(
        children: choices
            .map((choice) => RadioListTile<String>(
                  title: Text(
                    choice.choiceText,
                    style: const TextStyle(fontSize: 14),
                  ),
                  value: choice.id,
                  groupValue: selectedId,
                  onChanged: (value) {
                    setState(() {
                      _selected = {value!};
                    });
                    widget.onChanged(_selected);
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: const Color(0xFFFFBD59),
                ))
            .toList(),
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
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Type your answer here',
        hintStyle: const TextStyle(color: Color(0xFFCCCCCC)),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFBD59), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      onChanged: onChanged,
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
          style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
        ),
        const SizedBox(height: 8),
        ...List.generate(count, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: controllers[i],
              decoration: InputDecoration(
                hintText: 'Answer ${i + 1}',
                hintStyle: const TextStyle(color: Color(0xFFCCCCCC)),
                filled: true,
                fillColor: const Color(0xFFFAFAFA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFFFBD59), width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                prefixText: '${i + 1}. ',
                prefixStyle: const TextStyle(
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w600,
                ),
              ),
              onChanged: (value) => onChanged(i, value),
            ),
          );
        }),
      ],
    );
  }
}