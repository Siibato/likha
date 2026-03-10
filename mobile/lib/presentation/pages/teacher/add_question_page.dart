import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/utils/snackbar_utils.dart';
import 'package:likha/domain/assessments/usecases/add_questions.dart';
import 'package:likha/presentation/providers/assessment_provider.dart';
import 'package:likha/presentation/pages/teacher/widgets/question_type_dropdown.dart';

class AddQuestionPage extends ConsumerStatefulWidget {
  final String assessmentId;

  const AddQuestionPage({super.key, required this.assessmentId});

  @override
  ConsumerState<AddQuestionPage> createState() => _AddQuestionPageState();
}

class _AddQuestionPageState extends ConsumerState<AddQuestionPage> {
  final _formKey = GlobalKey<FormState>();
  final _questionTextController = TextEditingController();
  final _pointsController = TextEditingController(text: '1');
  String _questionType = 'multiple_choice';
  bool _isMultiSelect = false;

  // Multiple choice
  final List<_ChoiceEdit> _choices = [_ChoiceEdit(), _ChoiceEdit()];

  // Identification
  final List<TextEditingController> _acceptableAnswerControllers = [
    TextEditingController()
  ];

  // Enumeration
  final List<_EnumerationItemEdit> _enumerationItems = [];

  @override
  void dispose() {
    _questionTextController.dispose();
    _pointsController.dispose();
    for (final c in _choices) {
      c.controller.dispose();
    }
    for (final c in _acceptableAnswerControllers) {
      c.dispose();
    }
    for (final item in _enumerationItems) {
      for (final c in item.answerControllers) {
        c.dispose();
      }
    }
    super.dispose();
  }

  void _onTypeChanged(String? type) {
    if (type == null || type == _questionType) return;
    setState(() {
      _questionType = type;
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final points = int.tryParse(_pointsController.text.trim());
    if (points == null || points <= 0) {
      context.showErrorSnackBar('Please enter valid points');
      return;
    }

    final questionData = <String, dynamic>{
      'question_type': _questionType,
      'question_text': _questionTextController.text.trim(),
      'points': points,
      'order_index': 0,
    };

    if (_questionType == 'multiple_choice') {
      if (_choices.length < 2) {
        context.showErrorSnackBar('At least 2 choices are required');
        return;
      }
      if (!_choices.any((c) => c.isCorrect)) {
        context.showErrorSnackBar('At least one choice must be correct');
        return;
      }
      questionData['is_multi_select'] = _isMultiSelect;
      questionData['choices'] = _choices.asMap().entries.map((entry) {
        return {
          'choice_text': entry.value.controller.text.trim(),
          'is_correct': entry.value.isCorrect,
          'order_index': entry.key,
        };
      }).toList();
    } else if (_questionType == 'identification') {
      final answers = _acceptableAnswerControllers
          .where((c) => c.text.trim().isNotEmpty)
          .toList();
      if (answers.isEmpty) {
        context.showErrorSnackBar('At least one acceptable answer is required');
        return;
      }
      questionData['correct_answers'] =
          answers.map((c) => c.text.trim()).toList();
    } else if (_questionType == 'enumeration') {
      if (_enumerationItems.isEmpty) {
        context.showErrorSnackBar('At least one enumeration item is required');
        return;
      }
      questionData['enumeration_items'] =
          _enumerationItems.asMap().entries.map((entry) {
        return {
          'order_index': entry.key,
          'acceptable_answers': entry.value.answerControllers
              .where((c) => c.text.trim().isNotEmpty)
              .map((c) => c.text.trim())
              .toList(),
        };
      }).toList();
    }

    await ref.read(assessmentProvider.notifier).addQuestions(
          AddQuestionsParams(
            assessmentId: widget.assessmentId,
            questions: [questionData],
          ),
        );

    if (!mounted) return;
    final state = ref.read(assessmentProvider);
    if (state.error == null) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assessmentProvider);

    ref.listen<AssessmentState>(assessmentProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        context.showErrorSnackBar(next.error!);
        ref.read(assessmentProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Question'),
        actions: [
          TextButton(
            onPressed: state.isLoading ? null : _handleSave,
            child: state.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              QuestionTypeDropdown(
                value: _questionType,
                onChanged: state.isLoading ? (_) {} : _onTypeChanged,
                enabled: !state.isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _questionTextController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Question Text',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Question text is required';
                  }
                  return null;
                },
                enabled: !state.isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pointsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Points',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
                enabled: !state.isLoading,
              ),
              const SizedBox(height: 24),
              if (_questionType == 'multiple_choice')
                _buildMultipleChoiceSection(state.isLoading),
              if (_questionType == 'identification')
                _buildIdentificationSection(state.isLoading),
              if (_questionType == 'enumeration')
                _buildEnumerationSection(state.isLoading),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMultipleChoiceSection(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Allow multiple correct answers'),
          value: _isMultiSelect,
          onChanged: isLoading
              ? null
              : (value) {
                  setState(() {
                    _isMultiSelect = value;
                    if (!value) {
                      bool found = false;
                      for (final c in _choices) {
                        if (c.isCorrect && found) c.isCorrect = false;
                        if (c.isCorrect) found = true;
                      }
                    }
                  });
                },
        ),
        const Text('Choices',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 8),
        ..._choices.asMap().entries.map((entry) {
          final index = entry.key;
          final choice = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Checkbox(
                  value: choice.isCorrect,
                  onChanged: isLoading
                      ? null
                      : (value) {
                          setState(() {
                            if (!_isMultiSelect) {
                              for (final c in _choices) {
                                c.isCorrect = false;
                              }
                            }
                            choice.isCorrect = value ?? false;
                          });
                        },
                ),
                Expanded(
                  child: TextFormField(
                    controller: choice.controller,
                    decoration: InputDecoration(
                      labelText: 'Choice ${index + 1}',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                    enabled: !isLoading,
                  ),
                ),
                if (_choices.length > 2)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: isLoading
                        ? null
                        : () {
                            setState(() {
                              _choices[index].controller.dispose();
                              _choices.removeAt(index);
                            });
                          },
                  ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: isLoading
              ? null
              : () {
                  setState(() {
                    _choices.add(_ChoiceEdit());
                  });
                },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Choice'),
        ),
      ],
    );
  }

  Widget _buildIdentificationSection(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Acceptable Answers',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 4),
        Text(
          'Students can enter any of these answers (case-insensitive)',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 12),
        ..._acceptableAnswerControllers.asMap().entries.map((entry) {
          final index = entry.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: entry.value,
                    decoration: InputDecoration(
                      labelText: 'Answer ${index + 1}',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                    enabled: !isLoading,
                  ),
                ),
                if (_acceptableAnswerControllers.length > 1)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: isLoading
                        ? null
                        : () {
                            setState(() {
                              _acceptableAnswerControllers[index].dispose();
                              _acceptableAnswerControllers.removeAt(index);
                            });
                          },
                  ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: isLoading
              ? null
              : () {
                  setState(() {
                    _acceptableAnswerControllers.add(TextEditingController());
                  });
                },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Acceptable Answer'),
        ),
      ],
    );
  }

  Widget _buildEnumerationSection(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Enumeration Items',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 4),
        Text(
          'Each item can have multiple acceptable answers',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 12),
        ..._enumerationItems.asMap().entries.map((entry) {
          final itemIndex = entry.key;
          final item = entry.value;
          return Card(
            color: Colors.grey[50],
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Item ${itemIndex + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 20, color: Colors.red),
                        onPressed: isLoading
                            ? null
                            : () {
                                setState(() {
                                  for (final c in item.answerControllers) {
                                    c.dispose();
                                  }
                                  _enumerationItems.removeAt(itemIndex);
                                });
                              },
                      ),
                    ],
                  ),
                  ...item.answerControllers.asMap().entries.map((ae) {
                    final answerIndex = ae.key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: ae.value,
                              decoration: InputDecoration(
                                labelText: 'Variant ${answerIndex + 1}',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                isDense: true,
                              ),
                              enabled: !isLoading,
                            ),
                          ),
                          if (item.answerControllers.length > 1)
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        item.answerControllers[answerIndex]
                                            .dispose();
                                        item.answerControllers
                                            .removeAt(answerIndex);
                                      });
                                    },
                            ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: isLoading
                        ? null
                        : () {
                            setState(() {
                              item.answerControllers
                                  .add(TextEditingController());
                            });
                          },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Variant',
                        style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          );
        }),
        TextButton.icon(
          onPressed: isLoading
              ? null
              : () {
                  setState(() {
                    _enumerationItems.add(_EnumerationItemEdit(
                      answerControllers: [TextEditingController()],
                    ));
                  });
                },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Enumeration Item'),
        ),
      ],
    );
  }
}

class _ChoiceEdit {
  final TextEditingController controller;
  bool isCorrect;

  _ChoiceEdit({TextEditingController? controller, this.isCorrect = false})
      : controller = controller ?? TextEditingController();
}

class _EnumerationItemEdit {
  final List<TextEditingController> answerControllers;

  _EnumerationItemEdit({required this.answerControllers});
}
