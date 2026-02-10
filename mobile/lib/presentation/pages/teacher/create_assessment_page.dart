import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/domain/assessments/usecases/add_questions.dart';
import 'package:likha/domain/assessments/usecases/create_assessment.dart';
import 'package:likha/presentation/providers/assessment_provider.dart';

class CreateAssessmentPage extends ConsumerStatefulWidget {
  final String classId;

  const CreateAssessmentPage({super.key, required this.classId});

  @override
  ConsumerState<CreateAssessmentPage> createState() =>
      _CreateAssessmentPageState();
}

class _CreateAssessmentPageState extends ConsumerState<CreateAssessmentPage> {
  int _currentStep = 0;

  // Step 1: Assessment details
  final _detailsFormKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _timeLimitController = TextEditingController(text: '30');
  DateTime _openAt = DateTime.now();
  DateTime _closeAt = DateTime.now().add(const Duration(days: 7));
  bool _showResultsImmediately = false;

  // Step 2: Questions
  final List<_QuestionDraft> _questions = [];

  // Created assessment ID after step 1 save
  String? _createdAssessmentId;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _timeLimitController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year} $hour:$minute $period';
  }

  String _formatDateTimeForApi(DateTime dt) {
    final utc = dt.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}-'
        '${utc.month.toString().padLeft(2, '0')}-'
        '${utc.day.toString().padLeft(2, '0')}T'
        '${utc.hour.toString().padLeft(2, '0')}:'
        '${utc.minute.toString().padLeft(2, '0')}:'
        '${utc.second.toString().padLeft(2, '0')}';
  }

  Widget _buildDateTimeField({
    required String label,
    required DateTime value,
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: const Icon(Icons.arrow_drop_down),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabled: enabled,
        ),
        child: Text(
          _formatDateTime(value),
          style: TextStyle(
            fontSize: 16,
            color: enabled ? null : Colors.grey,
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateTime({
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    onPicked(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _handleCreateAssessment() async {
    if (!_detailsFormKey.currentState!.validate()) return;

    final timeLimit = int.tryParse(_timeLimitController.text.trim());
    if (timeLimit == null || timeLimit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid time limit'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_closeAt.isBefore(_openAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Close date must be after open date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await ref.read(assessmentProvider.notifier).createAssessment(
          CreateAssessmentParams(
            classId: widget.classId,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            timeLimitMinutes: timeLimit,
            openAt: _formatDateTimeForApi(_openAt),
            closeAt: _formatDateTimeForApi(_closeAt),
            showResultsImmediately: _showResultsImmediately,
          ),
        );

    if (!mounted) return;
    final state = ref.read(assessmentProvider);
    if (state.currentAssessment != null && state.error == null) {
      _createdAssessmentId = state.currentAssessment!.id;
      setState(() => _currentStep = 1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assessment created. Now add questions.'),
          backgroundColor: Colors.green,
        ),
      );
      ref.read(assessmentProvider.notifier).clearMessages();
    } else if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error!),
          backgroundColor: Colors.red,
        ),
      );
      ref.read(assessmentProvider.notifier).clearMessages();
    }
  }

  void _addQuestion() {
    setState(() {
      _questions.add(_QuestionDraft());
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  Future<void> _handleSaveQuestions() async {
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one question'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.questionText.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Question ${i + 1} text is empty'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (q.type == 'multiple_choice' && q.choices.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Question ${i + 1} needs at least 2 choices'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (q.type == 'multiple_choice' &&
          !q.choices.any((c) => c.isCorrect)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Question ${i + 1} needs at least one correct choice'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (q.type == 'identification' && q.acceptableAnswers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Question ${i + 1} needs at least one acceptable answer'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (q.type == 'enumeration' && q.enumerationItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Question ${i + 1} needs at least one enumeration item'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final questionsData = _questions.asMap().entries.map((entry) {
      final i = entry.key;
      final q = entry.value;
      final map = <String, dynamic>{
        'question_type': q.type,
        'question_text': q.questionText.trim(),
        'points': q.points,
        'order_index': i,
      };

      if (q.type == 'multiple_choice') {
        map['is_multi_select'] = q.isMultiSelect;
        map['choices'] = q.choices.asMap().entries.map((ce) {
          return {
            'choice_text': ce.value.text.trim(),
            'is_correct': ce.value.isCorrect,
            'order_index': ce.key,
          };
        }).toList();
      } else if (q.type == 'identification') {
        map['correct_answers'] = q.acceptableAnswers
            .where((a) => a.trim().isNotEmpty)
            .map((a) => a.trim())
            .toList();
      } else if (q.type == 'enumeration') {
        map['enumeration_items'] = q.enumerationItems.asMap().entries.map((ie) {
          return {
            'order_index': ie.key,
            'acceptable_answers': ie.value.answers
                .where((a) => a.trim().isNotEmpty)
                .map((a) => a.trim())
                .toList(),
          };
        }).toList();
      }

      return map;
    }).toList();

    await ref.read(assessmentProvider.notifier).addQuestions(
          AddQuestionsParams(
            assessmentId: _createdAssessmentId!,
            questions: questionsData,
          ),
        );

    if (!mounted) return;
    final state = ref.read(assessmentProvider);
    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error!), backgroundColor: Colors.red),
      );
      ref.read(assessmentProvider.notifier).clearMessages();
    } else {
      setState(() => _currentStep = 2);
      ref.read(assessmentProvider.notifier).clearMessages();
    }
  }

  void _handleFinish() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Assessment saved as draft'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final assessmentState = ref.watch(assessmentProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentStep == 0
            ? 'Create Assessment'
            : _currentStep == 1
                ? 'Add Questions'
                : 'Review'),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: null,
        onStepCancel: null,
        controlsBuilder: (context, details) => const SizedBox.shrink(),
        steps: [
          Step(
            title: const Text('Assessment Details'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: _buildDetailsStep(assessmentState),
          ),
          Step(
            title: const Text('Questions'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: _buildQuestionsStep(assessmentState),
          ),
          Step(
            title: const Text('Review'),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            content: _buildReviewStep(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsStep(AssessmentState assessmentState) {
    return Form(
      key: _detailsFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Title',
              prefixIcon: const Icon(Icons.title),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Title is required';
              }
              return null;
            },
            enabled: !assessmentState.isLoading,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description (optional)',
              prefixIcon: const Icon(Icons.description),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            enabled: !assessmentState.isLoading,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _timeLimitController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Time Limit (minutes)',
              prefixIcon: const Icon(Icons.timer),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Time limit is required';
              }
              final parsed = int.tryParse(value.trim());
              if (parsed == null || parsed <= 0) {
                return 'Enter a valid number of minutes';
              }
              return null;
            },
            enabled: !assessmentState.isLoading,
          ),
          const SizedBox(height: 16),
          _buildDateTimeField(
            label: 'Open Date',
            value: _openAt,
            icon: Icons.calendar_today,
            enabled: !assessmentState.isLoading,
            onTap: () => _pickDateTime(
              initial: _openAt,
              onPicked: (dt) => setState(() => _openAt = dt),
            ),
          ),
          const SizedBox(height: 16),
          _buildDateTimeField(
            label: 'Close Date',
            value: _closeAt,
            icon: Icons.event,
            enabled: !assessmentState.isLoading,
            onTap: () => _pickDateTime(
              initial: _closeAt,
              onPicked: (dt) => setState(() => _closeAt = dt),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Show results immediately'),
            subtitle:
                const Text('Students can see results right after submission'),
            value: _showResultsImmediately,
            onChanged: assessmentState.isLoading
                ? null
                : (value) =>
                    setState(() => _showResultsImmediately = value),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed:
                assessmentState.isLoading ? null : _handleCreateAssessment,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: assessmentState.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create & Continue',
                    style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildQuestionsStep(AssessmentState assessmentState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_questions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No questions added yet.\nTap the button below to add a question.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ..._questions.asMap().entries.map((entry) {
          final index = entry.key;
          final question = entry.value;
          return _QuestionCard(
            index: index,
            question: question,
            onRemove: () => _removeQuestion(index),
            onChanged: () => setState(() {}),
          );
        }),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: assessmentState.isLoading ? null : _addQuestion,
          icon: const Icon(Icons.add),
          label: const Text('Add Question'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: assessmentState.isLoading ? null : _handleSaveQuestions,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: assessmentState.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Questions & Review',
                  style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titleController.text,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (_descriptionController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(_descriptionController.text,
                      style: TextStyle(color: Colors.grey[600])),
                ],
                const Divider(height: 24),
                Text('Time Limit: ${_timeLimitController.text} minutes'),
                const SizedBox(height: 4),
                Text(
                    'Open: ${_formatDateTime(_openAt)}'),
                const SizedBox(height: 4),
                Text(
                    'Close: ${_formatDateTime(_closeAt)}'),
                const SizedBox(height: 4),
                Text(
                    'Show results immediately: ${_showResultsImmediately ? 'Yes' : 'No'}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Questions (${_questions.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ..._questions.asMap().entries.map((entry) {
          final i = entry.key;
          final q = entry.value;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Q${i + 1}. ${q.questionText}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_questionTypeLabel(q.type)} - ${q.points} point${q.points == 1 ? '' : 's'}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  if (q.type == 'multiple_choice') ...[
                    const SizedBox(height: 8),
                    ...q.choices.map((c) => Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2),
                          child: Row(
                            children: [
                              Icon(
                                c.isCorrect
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                size: 16,
                                color:
                                    c.isCorrect ? Colors.green : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(c.text)),
                            ],
                          ),
                        )),
                  ],
                  if (q.type == 'identification') ...[
                    const SizedBox(height: 8),
                    Text(
                      'Acceptable: ${q.acceptableAnswers.join(', ')}',
                      style:
                          TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                  if (q.type == 'enumeration') ...[
                    const SizedBox(height: 8),
                    ...q.enumerationItems.asMap().entries.map((ie) => Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2),
                          child: Text(
                            'Item ${ie.key + 1}: ${ie.value.answers.join(', ')}',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13),
                          ),
                        )),
                  ],
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _handleFinish,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child:
              const Text('Save as Draft', style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _questionTypeLabel(String type) {
    switch (type) {
      case 'multiple_choice':
        return 'Multiple Choice';
      case 'identification':
        return 'Identification';
      case 'enumeration':
        return 'Enumeration';
      default:
        return type;
    }
  }
}

// ---------------------------------------------------------------------------
// Local draft models
// ---------------------------------------------------------------------------

class _ChoiceDraft {
  String text;
  bool isCorrect;

  _ChoiceDraft({this.text = '', this.isCorrect = false});
}

class _EnumerationItemDraft {
  List<String> answers;

  _EnumerationItemDraft({List<String>? answers})
      : answers = answers ?? [''];
}

class _QuestionDraft {
  String type;
  String questionText;
  int points;
  bool isMultiSelect;
  List<_ChoiceDraft> choices;
  List<String> acceptableAnswers;
  List<_EnumerationItemDraft> enumerationItems;

  _QuestionDraft({
    this.type = 'multiple_choice',
    this.questionText = '',
    this.points = 1,
    this.isMultiSelect = false,
    List<_ChoiceDraft>? choices,
    List<String>? acceptableAnswers,
    List<_EnumerationItemDraft>? enumerationItems,
  })  : choices = choices ?? [_ChoiceDraft(), _ChoiceDraft()],
        acceptableAnswers = acceptableAnswers ?? [''],
        enumerationItems = enumerationItems ?? [];
}

// ---------------------------------------------------------------------------
// Question card widget
// ---------------------------------------------------------------------------

class _QuestionCard extends StatelessWidget {
  final int index;
  final _QuestionDraft question;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _QuestionCard({
    required this.index,
    required this.question,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Question ${index + 1}',
                    style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onRemove,
                  tooltip: 'Remove question',
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: question.type,
              decoration: InputDecoration(
                labelText: 'Question Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'multiple_choice', child: Text('Multiple Choice')),
                DropdownMenuItem(
                    value: 'identification', child: Text('Identification')),
                DropdownMenuItem(
                    value: 'enumeration', child: Text('Enumeration')),
              ],
              onChanged: (value) {
                if (value != null) {
                  question.type = value;
                  onChanged();
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: question.questionText,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Question Text',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                question.questionText = value;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: question.points.toString(),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Points',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                question.points = int.tryParse(value) ?? 1;
              },
            ),
            const SizedBox(height: 12),
            if (question.type == 'multiple_choice')
              _buildMultipleChoiceSection(context),
            if (question.type == 'identification')
              _buildIdentificationSection(context),
            if (question.type == 'enumeration')
              _buildEnumerationSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMultipleChoiceSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Allow multiple correct answers'),
          value: question.isMultiSelect,
          onChanged: (value) {
            question.isMultiSelect = value;
            if (!value) {
              // Keep only first correct
              bool found = false;
              for (final c in question.choices) {
                if (c.isCorrect && found) {
                  c.isCorrect = false;
                }
                if (c.isCorrect) found = true;
              }
            }
            onChanged();
          },
        ),
        ...question.choices.asMap().entries.map((entry) {
          final ci = entry.key;
          final choice = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Checkbox(
                  value: choice.isCorrect,
                  onChanged: (value) {
                    if (!question.isMultiSelect) {
                      for (final c in question.choices) {
                        c.isCorrect = false;
                      }
                    }
                    choice.isCorrect = value ?? false;
                    onChanged();
                  },
                ),
                Expanded(
                  child: TextFormField(
                    initialValue: choice.text,
                    decoration: InputDecoration(
                      labelText: 'Choice ${ci + 1}',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      choice.text = value;
                    },
                  ),
                ),
                if (question.choices.length > 2)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      question.choices.removeAt(ci);
                      onChanged();
                    },
                  ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () {
            question.choices.add(_ChoiceDraft());
            onChanged();
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Choice'),
        ),
      ],
    );
  }

  Widget _buildIdentificationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Acceptable Answers',
            style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        ...question.acceptableAnswers.asMap().entries.map((entry) {
          final ai = entry.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: entry.value,
                    decoration: InputDecoration(
                      labelText: 'Answer ${ai + 1}',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      question.acceptableAnswers[ai] = value;
                    },
                  ),
                ),
                if (question.acceptableAnswers.length > 1)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      question.acceptableAnswers.removeAt(ai);
                      onChanged();
                    },
                  ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () {
            question.acceptableAnswers.add('');
            onChanged();
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Acceptable Answer'),
        ),
      ],
    );
  }

  Widget _buildEnumerationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...question.enumerationItems.asMap().entries.map((entry) {
          final ii = entry.key;
          final item = entry.value;
          return Card(
            color: Colors.grey[50],
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Item ${ii + 1}',
                          style:
                              const TextStyle(fontWeight: FontWeight.w500)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 20, color: Colors.red),
                        onPressed: () {
                          question.enumerationItems.removeAt(ii);
                          onChanged();
                        },
                      ),
                    ],
                  ),
                  ...item.answers.asMap().entries.map((ae) {
                    final ai = ae.key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: ae.value,
                              decoration: InputDecoration(
                                labelText: 'Variant ${ai + 1}',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                isDense: true,
                              ),
                              onChanged: (value) {
                                item.answers[ai] = value;
                              },
                            ),
                          ),
                          if (item.answers.length > 1)
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                item.answers.removeAt(ai);
                                onChanged();
                              },
                            ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () {
                      item.answers.add('');
                      onChanged();
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Variant', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          );
        }),
        TextButton.icon(
          onPressed: () {
            question.enumerationItems.add(_EnumerationItemDraft());
            onChanged();
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Enumeration Item'),
        ),
      ],
    );
  }
}
