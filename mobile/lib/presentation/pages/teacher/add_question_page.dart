import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/assessments/usecases/add_questions.dart';
import 'package:likha/presentation/providers/assessment_provider.dart';
import 'package:likha/presentation/pages/teacher/widgets/question_type_dropdown.dart';
import 'package:likha/presentation/pages/teacher/widgets/assessment_field.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/form_message.dart';

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
  String? _formError;

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
      setState(() => _formError = 'Please enter valid points');
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
        setState(() => _formError = 'At least 2 choices are required');
        return;
      }
      if (!_choices.any((c) => c.isCorrect)) {
        setState(() => _formError = 'At least one choice must be correct');
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
        setState(() => _formError = 'At least one acceptable answer is required');
        return;
      }
      questionData['correct_answers'] =
          answers.map((c) => c.text.trim()).toList();
    } else if (_questionType == 'enumeration') {
      if (_enumerationItems.isEmpty) {
        setState(() => _formError = 'At least one enumeration item is required');
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
    } else {
      setState(() => _formError = AppErrorMapper.toUserMessage(state.error));
      ref.read(assessmentProvider.notifier).clearMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assessmentProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF2B2B2B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Question',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B2B),
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: state.isLoading ? null : _handleSave,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2B2B2B),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: state.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF2B2B2B),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FormMessage(
                message: _formError,
                severity: MessageSeverity.error,
              ),
              const SizedBox(height: 16),
              QuestionTypeDropdown(
                value: _questionType,
                onChanged: state.isLoading ? (_) {} : _onTypeChanged,
                enabled: !state.isLoading,
              ),
              const SizedBox(height: 16),
              AssessmentField(
                label: 'Question Text',
                icon: Icons.help_outline_rounded,
                controller: _questionTextController,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Question text is required';
                  }
                  return null;
                },
                enabled: !state.isLoading,
                onChanged: (_) => setState(() => _formError = null),
              ),
              const SizedBox(height: 16),
              AssessmentField(
                label: 'Points',
                icon: Icons.star_outline_rounded,
                controller: _pointsController,
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
                enabled: !state.isLoading,
                onChanged: (_) => setState(() => _formError = null),
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
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          margin: const EdgeInsets.only(bottom: 16),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Allow multiple correct answers'),
            value: _isMultiSelect,
            activeThumbColor: const Color(0xFF2B2B2B),
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
        ),
        const Text('Choices',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Color(0xFF2B2B2B),
              letterSpacing: -0.2,
            )),
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
                  activeColor: const Color(0xFF2B2B2B),
                  checkColor: Colors.white,
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
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF999999),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF2B2B2B),
                          width: 1.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFEF5350),
                          width: 1,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFEF5350),
                          width: 1.5,
                        ),
                      ),
                      isDense: true,
                    ),
                    enabled: !isLoading,
                  ),
                ),
                if (_choices.length > 2)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF666666)),
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
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF2B2B2B),
          ),
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
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Color(0xFF2B2B2B),
              letterSpacing: -0.2,
            )),
        const SizedBox(height: 4),
        const Text(
          'Students can enter any of these answers (case-insensitive)',
          style: TextStyle(color: Color(0xFF999999), fontSize: 13),
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
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF999999),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF2B2B2B),
                          width: 1.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFEF5350),
                          width: 1,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFEF5350),
                          width: 1.5,
                        ),
                      ),
                      isDense: true,
                    ),
                    enabled: !isLoading,
                  ),
                ),
                if (_acceptableAnswerControllers.length > 1)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF666666)),
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
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF2B2B2B),
          ),
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
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Color(0xFF2B2B2B),
              letterSpacing: -0.2,
            )),
        const SizedBox(height: 4),
        const Text(
          'Each item can have multiple acceptable answers',
          style: TextStyle(color: Color(0xFF999999), fontSize: 13),
        ),
        const SizedBox(height: 12),
        ..._enumerationItems.asMap().entries.map((entry) {
          final itemIndex = entry.key;
          final item = entry.value;
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            margin: const EdgeInsets.only(bottom: 12),
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
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 20, color: Color(0xFFEA4335)),
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
                              labelStyle: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF999999),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE0E0E0),
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE0E0E0),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF2B2B2B),
                                  width: 1.5,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFEF5350),
                                  width: 1,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFEF5350),
                                  width: 1.5,
                                ),
                              ),
                              isDense: true,
                            ),
                            enabled: !isLoading,
                          ),
                        ),
                        if (item.answerControllers.length > 1)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF666666)),
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
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2B2B2B),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Variant',
                      style: TextStyle(fontSize: 13)),
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
                    _enumerationItems.add(_EnumerationItemEdit(
                      answerControllers: [TextEditingController()],
                    ));
                  });
                },
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF2B2B2B),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Enumeration Item'),
        ),
      ],
    );
  }
}

class _ChoiceEdit {
  final TextEditingController controller;
  bool isCorrect = false;

  _ChoiceEdit({TextEditingController? controller})
      : controller = controller ?? TextEditingController();
}

class _EnumerationItemEdit {
  final List<TextEditingController> answerControllers;

  _EnumerationItemEdit({required this.answerControllers});
}
