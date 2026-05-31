import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/utils/snackbar_utils.dart';
import 'package:likha/domain/assessments/usecases/create_assessment.dart';
import 'package:likha/domain/assessments/usecases/add_questions.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/widgets/shared/forms/form_message.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/question_draft.dart';
import 'package:likha/presentation/providers/teacher_assessment_provider.dart';
import 'package:likha/presentation/providers/tos_provider.dart';
import 'package:likha/presentation/utils/formatters.dart';
import 'package:likha/presentation/widgets/shared/dialogs/styled_dialog.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assessment/assessment_settings_panel.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assessment/assessment_questions_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateAssessmentDesktop extends ConsumerStatefulWidget {
  final String classId;

  const CreateAssessmentDesktop({super.key, required this.classId});

  @override
  ConsumerState<CreateAssessmentDesktop> createState() =>
      _CreateAssessmentDesktopState();
}

class _CreateAssessmentDesktopState
    extends ConsumerState<CreateAssessmentDesktop> {
  // Settings form
  final _detailsFormKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _timeLimitController = TextEditingController(text: '30');
  DateTime _openAt = DateTime.now();
  DateTime _closeAt = DateTime.now().add(const Duration(days: 7));
  bool _showResultsImmediately = false;
  bool _isPublished = true;
  int? _quarter;
  String? _component;
  bool _isDepartmentalExam = false;
  String? _linkedTosId;

  // Questions
  final List<QuestionDraft> _questions = [];
  bool _isQuestionReorderMode = false;
  bool _isAddingQuestion = false;
  int? _editingQuestionIndex;

  // Page state
  bool _isSaving = false;
  bool _draftLoaded = false;
  String? _formError;
  Timer? _autoSaveTimer;

  String get _draftKey => 'assessment_draft_desktop_${widget.classId}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDraft();
      ref.read(tosProvider.notifier).loadTosList(widget.classId);
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    _timeLimitController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Draft persistence
  // ---------------------------------------------------------------------------

  Future<void> _loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftJson = prefs.getString(_draftKey);
      if (draftJson != null && mounted) {
        final draft = jsonDecode(draftJson) as Map<String, dynamic>;
        _titleController.text = draft['title'] as String? ?? '';
        _descriptionController.text = draft['description'] as String? ?? '';
        _timeLimitController.text = draft['timeLimitMinutes'].toString();
        _openAt = DateTime.parse(
          draft['openAt'] as String? ?? DateTime.now().toIso8601String(),
        );
        _closeAt = DateTime.parse(
          draft['closeAt'] as String? ??
              DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        );
        _showResultsImmediately =
            draft['showResultsImmediately'] as bool? ?? false;
        _isPublished = draft['isPublished'] as bool? ?? true;
        _quarter = draft['quarter'] as int?;
        _component = draft['component'] as String?;
        _isDepartmentalExam = draft['isDepartmentalExam'] as bool? ?? false;
        final questions = draft['questions'] as List?;
        if (questions != null) {
          _questions.clear();
          for (final q in questions) {
            _questions.add(QuestionDraft.fromJson(q as Map<String, dynamic>));
          }
        }
        setState(() => _draftLoaded = true);
      }
    } catch (_) {}
  }

  Future<void> _persistDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draft = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'timeLimitMinutes': int.tryParse(_timeLimitController.text) ?? 30,
        'openAt': _openAt.toIso8601String(),
        'closeAt': _closeAt.toIso8601String(),
        'showResultsImmediately': _showResultsImmediately,
        'isPublished': _isPublished,
        'quarter': _quarter,
        'component': _component,
        'isDepartmentalExam': _isDepartmentalExam,
        'questions': _questions.map((q) => q.toJson()).toList(),
      };
      await prefs.setString(_draftKey, jsonEncode(draft));
    } catch (_) {}
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer =
        Timer(const Duration(milliseconds: 800), _persistDraft);
  }

  Future<void> _saveDraftWithFeedback() async {
    await _persistDraft();
    if (mounted) context.showSuccessSnackBar('Draft saved', durationMs: 1500);
  }

  Future<void> _clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey);
    } catch (_) {}
  }

  Future<void> _discardDraft() async {
    await _clearDraft();
    if (mounted) {
      setState(() {
        _draftLoaded = false;
        _titleController.clear();
        _descriptionController.clear();
        _timeLimitController.text = '30';
        _openAt = DateTime.now();
        _closeAt = DateTime.now().add(const Duration(days: 7));
        _showResultsImmediately = false;
        _isPublished = true;
        _quarter = null;
        _component = null;
        _isDepartmentalExam = false;
        _linkedTosId = null;
        _questions.clear();
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Date/time picker
  // ---------------------------------------------------------------------------

  Future<void> _pickDateTime({
    required DateTime current,
    required ValueChanged<DateTime> onChanged,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.accentCharcoal,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: AppColors.accentCharcoal,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      initialEntryMode: TimePickerEntryMode.input,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.accentCharcoal,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: AppColors.accentCharcoal,
            secondary: AppColors.accentCharcoal,
            tertiary: AppColors.accentCharcoal,
            onTertiary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    onChanged(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  // ---------------------------------------------------------------------------
  // Reorder
  // ---------------------------------------------------------------------------

  void _showQuestionMoveDialog(int currentIndex) {
    showDialog(
      context: context,
      builder: (_) => _MoveQuestionDialog(
        currentIndex: currentIndex,
        questionCount: _questions.length,
        onMove: (ci, ni) {
          setState(() {
            final q = _questions.removeAt(ci);
            _questions.insert(ni, q);
          });
          _scheduleAutoSave();
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Validation & save
  // ---------------------------------------------------------------------------

  bool _validateAll() {
    if (!_detailsFormKey.currentState!.validate()) return false;

    final timeLimit = int.tryParse(_timeLimitController.text.trim());
    if (timeLimit == null || timeLimit <= 0) {
      setState(() => _formError = 'Please enter a valid time limit');
      return false;
    }

    if (_closeAt.isBefore(_openAt)) {
      setState(() => _formError = 'Close date must be after open date');
      return false;
    }

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.questionText.trim().isEmpty) {
        setState(() => _formError = 'Question ${i + 1} text is empty');
        return false;
      }
      if (q.type == 'multiple_choice' && q.choices.length < 2) {
        setState(
            () => _formError = 'Question ${i + 1} needs at least 2 choices');
        return false;
      }
      if (q.type == 'multiple_choice' &&
          !q.choices.any((c) => c.isCorrect)) {
        setState(() => _formError =
            'Question ${i + 1} needs at least one correct choice');
        return false;
      }
      if (q.type == 'identification' && q.acceptableAnswers.isEmpty) {
        setState(() => _formError =
            'Question ${i + 1} needs at least one acceptable answer');
        return false;
      }
      if (q.type == 'enumeration' && q.enumerationItems.isEmpty) {
        setState(() => _formError =
            'Question ${i + 1} needs at least one enumeration item');
        return false;
      }
    }

    return true;
  }

  List<Map<String, dynamic>> _buildQuestionsData() {
    return _questions.asMap().entries.map((entry) {
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
        map['enumeration_items'] =
            q.enumerationItems.asMap().entries.map((ie) {
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
  }

  Future<void> _handleSave() async {
    if (!_validateAll()) return;

    setState(() {
      _isSaving = true;
      _formError = null;
    });

    try {
      final questionsData = _buildQuestionsData();
      final assessment = await ref
          .read(teacherAssessmentProvider.notifier)
          .createAssessment(
            CreateAssessmentParams(
              classId: widget.classId,
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              timeLimitMinutes: int.parse(_timeLimitController.text.trim()),
              openAt: formatDateTimeForApi(_openAt),
              closeAt: formatDateTimeForApi(_closeAt),
              showResultsImmediately: _showResultsImmediately,
              isPublished: _isPublished,
              questions: _isPublished ? questionsData : null,
              gradingPeriodNumber: _quarter,
              component: _component,
            ),
          );

      if (!mounted) return;

      if (assessment == null) {
        final state = ref.read(teacherAssessmentProvider);
        setState(() {
          _formError = AppErrorMapper.toUserMessage(state.error);
          _isSaving = false;
        });
        return;
      }

      if (!_isPublished && _questions.isNotEmpty) {
        await ref.read(teacherAssessmentProvider.notifier).addQuestions(
              AddQuestionsParams(
                assessmentId: assessment.id,
                questions: questionsData,
              ),
            );
        if (!mounted) return;
        final state = ref.read(teacherAssessmentProvider);
        if (state.error != null) {
          setState(() {
            _formError = AppErrorMapper.toUserMessage(state.error);
            _isSaving = false;
          });
          return;
        }
      }

      await _clearDraft();
      ref.read(teacherAssessmentProvider.notifier).clearMessages();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _formError = 'An error occurred: $e';
          _isSaving = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final tosState = ref.watch(tosProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: 'Create Assessment',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        actions: [
          OutlinedButton(
            onPressed: _isSaving ? null : _saveDraftWithFeedback,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accentCharcoal,
              side: const BorderSide(color: AppColors.borderLight),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Save Draft',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed:
                _isSaving || _isQuestionReorderMode ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentCharcoal,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.borderLight,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save Assessment',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
          ),
        ],
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_draftLoaded) _DraftResumeBanner(onDiscard: _discardDraft),
            FormMessage(message: _formError, severity: MessageSeverity.error),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AssessmentSettingsPanel(
                    formKey: _detailsFormKey,
                    titleCtrl: _titleController,
                    descriptionCtrl: _descriptionController,
                    timeLimitCtrl: _timeLimitController,
                    openAt: _openAt,
                    closeAt: _closeAt,
                    showResultsImmediately: _showResultsImmediately,
                    isPublished: _isPublished,
                    quarter: _quarter,
                    component: _component,
                    isDepartmentalExam: _isDepartmentalExam,
                    linkedTosId: _linkedTosId,
                    isSaving: _isSaving,
                    tosState: tosState,
                    onPickOpenAt: () => _pickDateTime(
                      current: _openAt,
                      onChanged: (dt) {
                        setState(() {
                          _openAt = dt;
                          _formError = null;
                        });
                        _scheduleAutoSave();
                      },
                    ),
                    onPickCloseAt: () => _pickDateTime(
                      current: _closeAt,
                      onChanged: (dt) {
                        setState(() {
                          _closeAt = dt;
                          _formError = null;
                        });
                        _scheduleAutoSave();
                      },
                    ),
                    onShowResultsChanged: (v) {
                      setState(() {
                        _showResultsImmediately = v;
                        _formError = null;
                      });
                      _scheduleAutoSave();
                    },
                    onPublishChanged: (v) {
                      setState(() {
                        _isPublished = v;
                        _formError = null;
                      });
                      _scheduleAutoSave();
                    },
                    onQuarterChanged: (v) {
                      setState(() {
                        _quarter = v;
                        _formError = null;
                      });
                      _scheduleAutoSave();
                    },
                    onComponentChanged: (v) {
                      setState(() {
                        _component = v;
                        _isDepartmentalExam = false;
                        _formError = null;
                      });
                      _scheduleAutoSave();
                    },
                    onDepartmentalExamChanged: (v) {
                      setState(() {
                        _isDepartmentalExam = v;
                        _formError = null;
                      });
                      _scheduleAutoSave();
                    },
                    onLinkedTosChanged: (v) {
                      setState(() {
                        _linkedTosId = v;
                        _formError = null;
                      });
                      _scheduleAutoSave();
                    },
                    onAutoSave: _scheduleAutoSave,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: AssessmentQuestionsPanel(
                    questions: _questions,
                    isAddingQuestion: _isAddingQuestion,
                    isReorderMode: _isQuestionReorderMode,
                    isSaving: _isSaving,
                    editingQuestionIndex: _editingQuestionIndex,
                    onEnterReorderMode: () =>
                        setState(() => _isQuestionReorderMode = true),
                    onExitReorderMode: () {
                      setState(() => _isQuestionReorderMode = false);
                      _scheduleAutoSave();
                    },
                    onOpenAddForm: () =>
                        setState(() => _isAddingQuestion = true),
                    onCancelAdd: () =>
                        setState(() => _isAddingQuestion = false),
                    onEditQuestion: (i) =>
                        setState(() => _editingQuestionIndex = i),
                    onDeleteQuestion: (i) {
                      setState(() => _questions.removeAt(i));
                      _scheduleAutoSave();
                    },
                    onMoveQuestion: _showQuestionMoveDialog,
                    onConfirmAdd: (draft) {
                      setState(() {
                        _questions.add(draft);
                        _isAddingQuestion = false;
                      });
                      _scheduleAutoSave();
                    },
                    onSaveEdit: (i, updated) {
                      setState(() {
                        _questions[i] = updated;
                        _editingQuestionIndex = null;
                      });
                      _scheduleAutoSave();
                    },
                    onCancelEdit: () =>
                        setState(() => _editingQuestionIndex = null),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftResumeBanner extends StatelessWidget {
  final VoidCallback onDiscard;

  const _DraftResumeBanner({required this.onDiscard});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.restore_rounded,
              size: 16, color: AppColors.foregroundSecondary),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Resuming draft',
              style: TextStyle(
                  fontSize: 13, color: AppColors.foregroundSecondary),
            ),
          ),
          TextButton(
            onPressed: onDiscard,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.semanticError,
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            child: const Text(
              'Discard',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog to move a question to a new position.
class _MoveQuestionDialog extends StatefulWidget {
  final int currentIndex;
  final int questionCount;
  final void Function(int currentIndex, int newIndex) onMove;

  const _MoveQuestionDialog({
    required this.currentIndex,
    required this.questionCount,
    required this.onMove,
  });

  @override
  State<_MoveQuestionDialog> createState() => _MoveQuestionDialogState();
}

class _MoveQuestionDialogState extends State<_MoveQuestionDialog> {
  late final TextEditingController _posController;

  @override
  void initState() {
    super.initState();
    _posController = TextEditingController();
  }

  @override
  void dispose() {
    _posController.dispose();
    super.dispose();
  }

  void _handleMove() {
    final newPos = int.tryParse(_posController.text);
    if (newPos != null &&
        newPos >= 1 &&
        newPos <= widget.questionCount) {
      widget.onMove(widget.currentIndex, newPos - 1);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      title: 'Move Question',
      subtitle:
          'Question ${widget.currentIndex + 1} of ${widget.questionCount}',
      content: TextField(
        controller: _posController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        autofocus: true,
        decoration: StyledTextFieldDecoration.styled(
          labelText: 'New position (1–${widget.questionCount})',
        ),
      ),
      actions: [
        StyledDialogAction(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        StyledDialogAction(
          label: 'Move',
          isPrimary: true,
          onPressed: _handleMove,
        ),
      ],
    );
  }
}
