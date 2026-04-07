import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/assessments/usecases/add_questions.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/presentation/providers/teacher_assessment_provider.dart';
import 'package:likha/presentation/pages/teacher/widgets/question_type_dropdown.dart';
import 'package:likha/presentation/pages/teacher/widgets/assessment_field.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/form_message.dart';
import 'package:likha/presentation/pages/teacher/widgets/question_editor_body.dart';
export 'package:likha/presentation/pages/teacher/widgets/question_editor_body.dart'
    show ChoiceEntry, EnumerationItemEntry, EditorStyleVariant;

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
  final _questionTextController = TextEditingController();
  final _pointsController = TextEditingController(text: '1');
  String _questionType = 'multiple_choice';
  bool _isMultiSelect = false;
  String? _selectedCompetencyId;
  String? _selectedCognitiveLevel;
  String? _formError;

  // Multiple choice
  final List<ChoiceEntry> _choices = [ChoiceEntry(), ChoiceEntry()];

  // Identification
  final List<TextEditingController> _acceptableAnswerControllers = [
    TextEditingController()
  ];

  // Enumeration
  final List<EnumerationItemEntry> _enumerationItems = [];

  @override
  void dispose() {
    _questionTextController.dispose();
    _pointsController.dispose();
    for (final c in _choices) {
      c.dispose();
    }
    for (final c in _acceptableAnswerControllers) {
      c.dispose();
    }
    for (final item in _enumerationItems) {
      item.dispose();
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
      if (_selectedCompetencyId != null)
        'tos_competency_id': _selectedCompetencyId,
      if (_selectedCognitiveLevel != null)
        'cognitive_level': _selectedCognitiveLevel,
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

    await ref.read(teacherAssessmentProvider.notifier).addQuestions(
          AddQuestionsParams(
            assessmentId: widget.assessmentId,
            questions: [questionData],
          ),
        );

    if (!mounted) return;
    final state = ref.read(teacherAssessmentProvider);
    if (state.error == null) {
      Navigator.pop(context, true);
    } else {
      setState(() => _formError = AppErrorMapper.toUserMessage(state.error));
      ref.read(teacherAssessmentProvider.notifier).clearMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teacherAssessmentProvider);

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
              // TOS competency & cognitive level dropdowns
              if (widget.tosId != null && widget.tosCompetencies.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: DropdownButtonFormField<String?>(
                    value: _selectedCompetencyId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Competency (optional)',
                      prefixIcon: Icon(Icons.list_alt_rounded, color: Color(0xFF999999), size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      labelStyle: TextStyle(fontSize: 14, color: Color(0xFF999999)),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      ...widget.tosCompetencies.map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              c.competencyCode != null
                                  ? '${c.competencyCode} - ${c.competencyText}'
                                  : c.competencyText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                    ],
                    onChanged: state.isLoading
                        ? null
                        : (v) => setState(() => _selectedCompetencyId = v),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: DropdownButtonFormField<String?>(
                    value: _selectedCognitiveLevel,
                    decoration: const InputDecoration(
                      labelText: 'Cognitive Level (optional)',
                      prefixIcon: Icon(Icons.psychology_outlined, color: Color(0xFF999999), size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      labelStyle: TextStyle(fontSize: 14, color: Color(0xFF999999)),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      if (widget.classificationMode == 'blooms') ...[
                        const DropdownMenuItem(value: 'Remembering', child: Text('Remembering')),
                        const DropdownMenuItem(value: 'Understanding', child: Text('Understanding')),
                        const DropdownMenuItem(value: 'Applying', child: Text('Applying')),
                        const DropdownMenuItem(value: 'Analyzing', child: Text('Analyzing')),
                        const DropdownMenuItem(value: 'Evaluating', child: Text('Evaluating')),
                        const DropdownMenuItem(value: 'Creating', child: Text('Creating')),
                      ] else ...[
                        const DropdownMenuItem(value: 'Easy', child: Text('Easy')),
                        const DropdownMenuItem(value: 'Average', child: Text('Average')),
                        const DropdownMenuItem(value: 'Difficult', child: Text('Difficult')),
                      ],
                    ],
                    onChanged: state.isLoading
                        ? null
                        : (v) => setState(() => _selectedCognitiveLevel = v),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (_questionType == 'multiple_choice')
                QuestionEditorBody(
                  questionType: 'multiple_choice',
                  choices: _choices,
                  isMultiSelect: _isMultiSelect,
                  isLoading: state.isLoading,
                  variant: EditorStyleVariant.form,
                  onMultiSelectChanged: (value) => setState(() {
                    _isMultiSelect = value;
                    if (!value) {
                      bool found = false;
                      for (final c in _choices) {
                        if (c.isCorrect && found) c.isCorrect = false;
                        if (c.isCorrect) found = true;
                      }
                    }
                  }),
                  onChoiceCorrectChanged: (index, isCorrect) => setState(() {
                    _choices[index].isCorrect = isCorrect;
                  }),
                  onChoiceTextChanged: (index, text) => setState(() {
                    _choices[index].controller.text = text;
                  }),
                  onAddChoice: () => setState(() => _choices.add(ChoiceEntry())),
                  onRemoveChoice: (index) => setState(() {
                    _choices[index].dispose();
                    _choices.removeAt(index);
                  }),
                  onStructuralChange: () => setState(() {}),
                ),
              if (_questionType == 'identification')
                QuestionEditorBody(
                  questionType: 'identification',
                  answerItems: _acceptableAnswerControllers,
                  isLoading: state.isLoading,
                  variant: EditorStyleVariant.form,
                  onAnswerChanged: (index, text) => setState(() {
                    _acceptableAnswerControllers[index].text = text;
                  }),
                  onAddAnswer: () => setState(() {
                    _acceptableAnswerControllers.add(TextEditingController());
                  }),
                  onRemoveAnswer: (index) => setState(() {
                    _acceptableAnswerControllers[index].dispose();
                    _acceptableAnswerControllers.removeAt(index);
                  }),
                  onStructuralChange: () => setState(() {}),
                ),
              if (_questionType == 'enumeration')
                QuestionEditorBody(
                  questionType: 'enumeration',
                  enumerationItems: _enumerationItems,
                  isLoading: state.isLoading,
                  variant: EditorStyleVariant.form,
                  onEnumAnswerChanged: (itemIndex, answerIndex, text) => setState(() {
                    _enumerationItems[itemIndex].answerControllers[answerIndex].text = text;
                  }),
                  onAddEnumItem: () => setState(() {
                    _enumerationItems.add(EnumerationItemEntry(
                      answerControllers: [TextEditingController()],
                    ));
                  }),
                  onRemoveEnumItem: (itemIndex) => setState(() {
                    _enumerationItems[itemIndex].dispose();
                    _enumerationItems.removeAt(itemIndex);
                  }),
                  onAddEnumAnswer: (itemIndex) => setState(() {
                    _enumerationItems[itemIndex].answerControllers.add(TextEditingController());
                  }),
                  onRemoveEnumAnswer: (itemIndex, answerIndex) => setState(() {
                    _enumerationItems[itemIndex].answerControllers[answerIndex].dispose();
                    _enumerationItems[itemIndex].answerControllers.removeAt(answerIndex);
                  }),
                  onStructuralChange: () => setState(() {}),
                ),
            ],
          ),
        ),
      ),
    );
  }

}
