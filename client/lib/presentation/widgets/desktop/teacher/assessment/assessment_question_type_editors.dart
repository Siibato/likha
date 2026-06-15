import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/question_draft.dart';

InputDecoration assessmentInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle:
        const TextStyle(fontSize: 14, color: AppColors.foregroundTertiary),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.borderLight),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.borderLight),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide:
          const BorderSide(color: AppColors.accentCharcoal, width: 1.5),
    ),
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}

class QuestionChoicesEditor extends StatefulWidget {
  final List<ChoiceDraft> initial;
  final bool isMultiSelect;
  final void Function(List<ChoiceDraft>) onChanged;

  const QuestionChoicesEditor({
    super.key,
    required this.initial,
    required this.isMultiSelect,
    required this.onChanged,
  });

  @override
  State<QuestionChoicesEditor> createState() => _QuestionChoicesEditorState();
}

class _QuestionChoicesEditorState extends State<QuestionChoicesEditor> {
  late List<ChoiceDraft> _choices;
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _choices = widget.initial
        .map((c) => ChoiceDraft(text: c.text, isCorrect: c.isCorrect))
        .toList();
    _controllers =
        _choices.map((c) => TextEditingController(text: c.text)).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _notify() => widget.onChanged(
        _choices.map((c) => ChoiceDraft(text: c.text, isCorrect: c.isCorrect)).toList(),
      );

  void _add() {
    setState(() {
      _choices.add(ChoiceDraft());
      _controllers.add(TextEditingController());
    });
    _notify();
  }

  void _remove(int i) {
    _controllers[i].dispose();
    setState(() {
      _choices.removeAt(i);
      _controllers.removeAt(i);
    });
    _notify();
  }

  void _setCorrect(int i, bool v) {
    setState(() {
      if (!widget.isMultiSelect && v) {
        for (final c in _choices) {
          c.isCorrect = false;
        }
      }
      _choices[i].isCorrect = v;
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choices',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.accentCharcoal,
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(_choices.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Checkbox(
                  value: _choices[i].isCorrect,
                  activeColor: AppColors.accentCharcoal,
                  onChanged: (v) => _setCorrect(i, v ?? false),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _controllers[i],
                    decoration: assessmentInputDecoration('Choice ${i + 1}'),
                    onChanged: (v) {
                      _choices[i].text = v;
                      _notify();
                    },
                  ),
                ),
                if (_choices.length > 2)
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.semanticError,
                    ),
                    onPressed: () => _remove(i),
                  ),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Choice'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.foregroundSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class QuestionAnswersEditor extends StatefulWidget {
  final List<String> initial;
  final void Function(List<String>) onChanged;

  const QuestionAnswersEditor({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  @override
  State<QuestionAnswersEditor> createState() => _QuestionAnswersEditorState();
}

class _QuestionAnswersEditorState extends State<QuestionAnswersEditor> {
  late List<String> _answers;
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _answers = List<String>.from(widget.initial);
    _controllers =
        _answers.map((a) => TextEditingController(text: a)).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _notify() => widget.onChanged(List<String>.from(_answers));

  void _add() {
    setState(() {
      _answers.add('');
      _controllers.add(TextEditingController());
    });
    _notify();
  }

  void _remove(int i) {
    _controllers[i].dispose();
    setState(() {
      _answers.removeAt(i);
      _controllers.removeAt(i);
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acceptable Answers',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.accentCharcoal,
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(_answers.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _controllers[i],
                    decoration: assessmentInputDecoration('Answer ${i + 1}'),
                    onChanged: (v) {
                      _answers[i] = v;
                      _notify();
                    },
                  ),
                ),
                if (_answers.length > 1)
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.semanticError,
                    ),
                    onPressed: () => _remove(i),
                  ),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Answer'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.foregroundSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class QuestionEnumerationEditor extends StatefulWidget {
  final List<EnumerationItemDraft> initial;
  final void Function(List<EnumerationItemDraft>) onChanged;

  const QuestionEnumerationEditor({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  @override
  State<QuestionEnumerationEditor> createState() =>
      _QuestionEnumerationEditorState();
}

class _QuestionEnumerationEditorState
    extends State<QuestionEnumerationEditor> {
  late List<EnumerationItemDraft> _items;
  late List<List<TextEditingController>> _controllers;

  @override
  void initState() {
    super.initState();
    _items = widget.initial
        .map((e) =>
            EnumerationItemDraft(answers: List<String>.from(e.answers)))
        .toList();
    _controllers = _items
        .map((item) =>
            item.answers.map((a) => TextEditingController(text: a)).toList())
        .toList();
  }

  @override
  void dispose() {
    for (final group in _controllers) {
      for (final c in group) {
        c.dispose();
      }
    }
    super.dispose();
  }

  void _notify() => widget.onChanged(
        _items
            .map((e) => EnumerationItemDraft(
                  answers: List<String>.from(e.answers),
                ))
            .toList(),
      );

  void _addItem() {
    setState(() {
      _items.add(EnumerationItemDraft());
      _controllers.add([TextEditingController()]);
    });
    _notify();
  }

  void _removeItem(int i) {
    for (final c in _controllers[i]) {
      c.dispose();
    }
    setState(() {
      _items.removeAt(i);
      _controllers.removeAt(i);
    });
    _notify();
  }

  void _addAnswer(int itemIndex) {
    setState(() {
      _items[itemIndex].answers.add('');
      _controllers[itemIndex].add(TextEditingController());
    });
    _notify();
  }

  void _removeAnswer(int itemIndex, int ansIndex) {
    _controllers[itemIndex][ansIndex].dispose();
    setState(() {
      _items[itemIndex].answers.removeAt(ansIndex);
      _controllers[itemIndex].removeAt(ansIndex);
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enumeration Items',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.accentCharcoal,
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(_items.length, (itemIndex) {
          final item = _items[itemIndex];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Item ${itemIndex + 1}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentCharcoal,
                      ),
                    ),
                    const Spacer(),
                    if (_items.length > 1)
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: AppColors.semanticError,
                        ),
                        onPressed: () => _removeItem(itemIndex),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                ...List.generate(item.answers.length, (ansIndex) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _controllers[itemIndex][ansIndex],
                            decoration: assessmentInputDecoration(
                              'Acceptable answer ${ansIndex + 1}',
                            ),
                            onChanged: (v) {
                              item.answers[ansIndex] = v;
                              _notify();
                            },
                          ),
                        ),
                        if (item.answers.length > 1)
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppColors.semanticError,
                            ),
                            onPressed: () =>
                                _removeAnswer(itemIndex, ansIndex),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.only(left: 4),
                          ),
                      ],
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: () => _addAnswer(itemIndex),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text(
                    'Add Answer',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.foregroundSecondary,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Item'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.foregroundSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
