import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/domain/assessments/usecases/update_question.dart';
import 'package:likha/presentation/providers/assessment_provider.dart';
import 'package:likha/presentation/pages/teacher/widgets/assessment_field.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/form_message.dart';

class EditQuestionPage extends ConsumerStatefulWidget {
  final Question question;
  final bool hasSubmissions;

  const EditQuestionPage({
    super.key,
    required this.question,
    required this.hasSubmissions,
  });

  @override
  ConsumerState<EditQuestionPage> createState() => _EditQuestionPageState();
}

class _EditQuestionPageState extends ConsumerState<EditQuestionPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _questionTextController;
  late TextEditingController _pointsController;
  late String _questionType;
  late bool _isMultiSelect;
  String? _formError;

  // Multiple choice
  late List<_ChoiceEdit> _choices;

  // Identification
  late List<TextEditingController> _acceptableAnswerControllers;

  // Enumeration
  late List<_EnumerationItemEdit> _enumerationItems;

  @override
  void initState() {
    super.initState();
    _questionTextController =
        TextEditingController(text: widget.question.questionText);
    _pointsController =
        TextEditingController(text: widget.question.points.toString());
    _questionType = widget.question.questionType;
    _isMultiSelect = widget.question.isMultiSelect;

    // Initialize choices
    _choices = widget.question.choices
            ?.map((c) => _ChoiceEdit(
                  id: c.id,
                  controller: TextEditingController(text: c.choiceText),
                  isCorrect: c.isCorrect,
                ))
            .toList() ??
        [_ChoiceEdit(), _ChoiceEdit()];

    // Initialize acceptable answers
    _acceptableAnswerControllers = widget.question.correctAnswers
            ?.map((a) => TextEditingController(text: a.answerText))
            .toList() ??
        [TextEditingController()];

    // Initialize enumeration items
    _enumerationItems = widget.question.enumerationItems
            ?.map((item) => _EnumerationItemEdit(
                  id: item.id,
                  answerControllers: item.acceptableAnswers
                      .map((a) => TextEditingController(text: a.answerText))
                      .toList(),
                ))
            .toList() ??
        [];
  }

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

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final points = int.tryParse(_pointsController.text.trim());
    if (points == null || points <= 0) {
      setState(() => _formError = 'Please enter valid points');
      return;
    }

    // Build the update data
    final data = <String, dynamic>{
      'question_text': _questionTextController.text.trim(),
      'points': points,
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

      data['is_multi_select'] = _isMultiSelect;
      data['choices'] = _choices.asMap().entries.map((entry) {
        final c = entry.value;
        return {
          if (c.id != null) 'id': c.id,
          'choice_text': c.controller.text.trim(),
          'is_correct': c.isCorrect,
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

      data['correct_answers'] =
          answers.map((c) => c.text.trim()).toList();
    } else if (_questionType == 'enumeration') {
      if (_enumerationItems.isEmpty) {
        setState(() => _formError = 'At least one enumeration item is required');
        return;
      }

      data['enumeration_items'] =
          _enumerationItems.asMap().entries.map((entry) {
        final item = entry.value;
        return {
          if (item.id != null) 'id': item.id,
          'order_index': entry.key,
          'acceptable_answers': item.answerControllers
              .where((c) => c.text.trim().isNotEmpty)
              .map((c) => c.text.trim())
              .toList(),
        };
      }).toList();
    }

    await ref.read(assessmentProvider.notifier).updateQuestion(
          UpdateQuestionParams(
            questionId: widget.question.id,
            data: data,
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
          'Edit Question',
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
              if (widget.hasSubmissions) ...[
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
              ],
              _buildQuestionTypeDisplay(),
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

  Widget _buildQuestionTypeDisplay() {
    String label;

    switch (_questionType) {
      case 'multiple_choice':
        label = 'Multiple Choice';
        break;
      case 'identification':
        label = 'Identification';
        break;
      case 'enumeration':
        label = 'Enumeration';
        break;
      default:
        label = _questionType;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF666666), size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2B2B2B),
              fontSize: 16,
            ),
          ),
          const Spacer(),
          const Text(
            'Question type cannot be changed',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF999999),
            ),
          ),
        ],
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
            activeColor: const Color(0xFF2B2B2B),
            onChanged: isLoading
                ? null
                : (value) {
                    setState(() {
                      _isMultiSelect = value;
                      if (!value) {
                        // Keep only first correct
                        bool found = false;
                        for (final c in _choices) {
                          if (c.isCorrect && found) {
                            c.isCorrect = false;
                          }
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
        Text(
          'Students can enter any of these answers (case-insensitive)',
          style: const TextStyle(color: Color(0xFF999999), fontSize: 13),
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
        Text(
          'Each item can have multiple acceptable answers',
          style: const TextStyle(color: Color(0xFF999999), fontSize: 13),
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
                  label:
                      const Text('Add Variant', style: TextStyle(fontSize: 13)),
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
  final String? id;
  final TextEditingController controller;
  bool isCorrect;

  _ChoiceEdit({this.id, TextEditingController? controller, this.isCorrect = false})
      : controller = controller ?? TextEditingController();
}

class _EnumerationItemEdit {
  final String? id;
  final List<TextEditingController> answerControllers;

  _EnumerationItemEdit({this.id, required this.answerControllers});
}
