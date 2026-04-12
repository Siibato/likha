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
import 'package:likha/presentation/pages/shared/widgets/forms/form_message.dart';
import 'package:likha/presentation/pages/teacher/widgets/question_draft.dart';
import 'package:likha/presentation/providers/teacher_assessment_provider.dart';
import 'package:likha/presentation/providers/tos_provider.dart';
import 'package:likha/presentation/utils/formatters.dart';
import 'package:likha/presentation/widgets/styled_dialog.dart';
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
  // Form state
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
  final List<QuestionDraft> _questions = [];
  bool _isSaving = false;
  bool _draftLoaded = false;
  Timer? _autoSaveTimer;
  bool _isQuestionReorderMode = false;
  String? _formError;
  bool _isAddingQuestion = false;

  // Add-question form state
  final _addQuestionFormKey = GlobalKey<FormState>();
  String _newQuestionType = 'multiple_choice';
  final _newQuestionTextController = TextEditingController();
  final _newQuestionPointsController = TextEditingController(text: '1');
  bool _newQuestionMultiSelect = false;
  List<ChoiceDraft> _newChoices = [ChoiceDraft(), ChoiceDraft()];
  List<String> _newAcceptableAnswers = [''];
  List<EnumerationItemDraft> _newEnumerationItems = [EnumerationItemDraft()];

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
    _newQuestionTextController.dispose();
    _newQuestionPointsController.dispose();
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
            _questions
                .add(QuestionDraft.fromJson(q as Map<String, dynamic>));
          }
        }

        setState(() => _draftLoaded = true);
      }
    } catch (_) {
      // Ignore draft load errors
    }
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
    } catch (_) {
      // Ignore persistence errors
    }
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 800), _persistDraft);
  }

  Future<void> _saveDraftWithFeedback() async {
    await _persistDraft();
    if (mounted) {
      context.showSuccessSnackBar('Draft saved', durationMs: 1500);
    }
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
  // Reorder
  // ---------------------------------------------------------------------------

  void _enterQuestionReorderMode() {
    setState(() => _isQuestionReorderMode = true);
  }

  void _exitQuestionReorderMode() {
    setState(() => _isQuestionReorderMode = false);
    _scheduleAutoSave();
  }

  void _showQuestionMoveDialog(int currentIndex) {
    showDialog(
      context: context,
      builder: (_) => _MoveQuestionDialog(
        currentIndex: currentIndex,
        questionCount: _questions.length,
        onMove: (int ci, int ni) {
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
  // Add question inline form
  // ---------------------------------------------------------------------------

  void _resetAddQuestionForm() {
    _newQuestionType = 'multiple_choice';
    _newQuestionTextController.clear();
    _newQuestionPointsController.text = '1';
    _newQuestionMultiSelect = false;
    _newChoices = [ChoiceDraft(), ChoiceDraft()];
    _newAcceptableAnswers = [''];
    _newEnumerationItems = [EnumerationItemDraft()];
  }

  void _openAddQuestionForm() {
    _resetAddQuestionForm();
    setState(() => _isAddingQuestion = true);
  }

  void _cancelAddQuestion() {
    setState(() => _isAddingQuestion = false);
  }

  void _confirmAddQuestion() {
    if (!_addQuestionFormKey.currentState!.validate()) return;

    final points = int.tryParse(_newQuestionPointsController.text.trim()) ?? 1;

    // Validate type-specific fields
    if (_newQuestionType == 'multiple_choice') {
      final nonEmpty =
          _newChoices.where((c) => c.text.trim().isNotEmpty).toList();
      if (nonEmpty.length < 2) {
        context.showErrorSnackBar('At least 2 choices are required');
        return;
      }
      if (!nonEmpty.any((c) => c.isCorrect)) {
        context.showErrorSnackBar('Mark at least one correct choice');
        return;
      }
    } else if (_newQuestionType == 'identification') {
      final nonEmpty =
          _newAcceptableAnswers.where((a) => a.trim().isNotEmpty).toList();
      if (nonEmpty.isEmpty) {
        context.showErrorSnackBar('At least one acceptable answer is required');
        return;
      }
    } else if (_newQuestionType == 'enumeration') {
      if (_newEnumerationItems.isEmpty) {
        context.showErrorSnackBar('At least one enumeration item is required');
        return;
      }
      for (int i = 0; i < _newEnumerationItems.length; i++) {
        final nonEmpty = _newEnumerationItems[i]
            .answers
            .where((a) => a.trim().isNotEmpty)
            .toList();
        if (nonEmpty.isEmpty) {
          context.showErrorSnackBar(
            'Item ${i + 1} needs at least one acceptable answer',
          );
          return;
        }
      }
    }

    final draft = QuestionDraft(
      type: _newQuestionType,
      questionText: _newQuestionTextController.text.trim(),
      points: points,
      isMultiSelect: _newQuestionMultiSelect,
      choices: _newQuestionType == 'multiple_choice'
          ? _newChoices
              .where((c) => c.text.trim().isNotEmpty)
              .map((c) => ChoiceDraft(text: c.text.trim(), isCorrect: c.isCorrect))
              .toList()
          : [ChoiceDraft(), ChoiceDraft()],
      acceptableAnswers: _newQuestionType == 'identification'
          ? _newAcceptableAnswers
              .where((a) => a.trim().isNotEmpty)
              .map((a) => a.trim())
              .toList()
          : [''],
      enumerationItems: _newQuestionType == 'enumeration'
          ? _newEnumerationItems
          : [],
    );

    setState(() {
      _questions.add(draft);
      _isAddingQuestion = false;
    });
    _scheduleAutoSave();
  }

  // ---------------------------------------------------------------------------
  // Validation & save
  // ---------------------------------------------------------------------------

  bool _validateAll() {
    if (!_detailsFormKey.currentState!.validate()) return false;

    final timeLimit = int.tryParse(_timeLimitController.text.trim());
    if (timeLimit == null || timeLimit <= 0) {
      setState(
          () => _formError = 'Please enter a valid time limit');
      return false;
    }

    if (_closeAt.isBefore(_openAt)) {
      setState(() => _formError = 'Close date must be after open date');
      return false;
    }

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.questionText.trim().isEmpty) {
        setState(
            () => _formError = 'Question ${i + 1} text is empty');
        return false;
      }
      if (q.type == 'multiple_choice' && q.choices.length < 2) {
        setState(() =>
            _formError = 'Question ${i + 1} needs at least 2 choices');
        return false;
      }
      if (q.type == 'multiple_choice' && !q.choices.any((c) => c.isCorrect)) {
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
              quarter: _quarter,
              component: _component,
              isDepartmentalExam: _isDepartmentalExam ? true : null,
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

      final assessmentId = assessment.id;

      if (!_isPublished && _questions.isNotEmpty) {
        await ref.read(teacherAssessmentProvider.notifier).addQuestions(
              AddQuestionsParams(
                assessmentId: assessmentId,
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
      if (mounted) {
        Navigator.pop(context, true);
      }
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
  // Date/time picker helpers
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2B2B2B),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF2B2B2B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      initialEntryMode: TimePickerEntryMode.input,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2B2B2B),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF2B2B2B),
              secondary: Color(0xFF2B2B2B),
              tertiary: Color(0xFF2B2B2B),
              onTertiary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time == null || !mounted) return;

    onChanged(
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
            ? 12
            : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year} $hour:$minute $period';
  }

  // ---------------------------------------------------------------------------
  // Shared input decoration
  // ---------------------------------------------------------------------------

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
      filled: true,
      fillColor: Colors.white,
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
        borderSide: const BorderSide(color: Color(0xFF2B2B2B), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
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
              foregroundColor: const Color(0xFF2B2B2B),
              side: const BorderSide(color: Color(0xFFE0E0E0)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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
              backgroundColor: const Color(0xFF2B2B2B),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE0E0E0),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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
            // Draft resume banner
            if (_draftLoaded)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.restore_rounded,
                        size: 16, color: Color(0xFF666666)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Resuming draft',
                        style: TextStyle(
                            fontSize: 13, color: Color(0xFF666666)),
                      ),
                    ),
                    TextButton(
                      onPressed: _discardDraft,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFE57373),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                      ),
                      child: const Text(
                        'Discard',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            // Form error
            FormMessage(
              message: _formError,
              severity: MessageSeverity.error,
            ),

            // Split view
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left panel -- settings form
                Expanded(child: _buildSettingsPanel(tosState)),
                const SizedBox(width: 24),
                // Right panel -- questions
                Expanded(child: _buildQuestionsPanel()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Left panel: Assessment settings
  // ---------------------------------------------------------------------------

  Widget _buildSettingsPanel(TosState tosState) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _detailsFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assessment Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2B2B2B),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration('Title'),
              enabled: !_isSaving,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
              onChanged: (_) => _scheduleAutoSave(),
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: _inputDecoration('Description (optional)'),
              maxLines: 3,
              enabled: !_isSaving,
              onChanged: (_) => _scheduleAutoSave(),
            ),
            const SizedBox(height: 16),

            // Time limit
            TextFormField(
              controller: _timeLimitController,
              decoration: _inputDecoration('Time Limit (minutes)'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              enabled: !_isSaving,
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
              onChanged: (_) => _scheduleAutoSave(),
            ),
            const SizedBox(height: 16),

            // Open date
            _buildDateTimeField(
              label: 'Open Date',
              dateTime: _openAt,
              onPick: () => _pickDateTime(
                current: _openAt,
                onChanged: (dt) {
                  setState(() {
                    _openAt = dt;
                    _formError = null;
                  });
                  _scheduleAutoSave();
                },
              ),
            ),
            const SizedBox(height: 16),

            // Close date
            _buildDateTimeField(
              label: 'Close Date',
              dateTime: _closeAt,
              onPick: () => _pickDateTime(
                current: _closeAt,
                onChanged: (dt) {
                  setState(() {
                    _closeAt = dt;
                    _formError = null;
                  });
                  _scheduleAutoSave();
                },
              ),
            ),
            const SizedBox(height: 12),

            // Show results toggle
            _buildSwitchTile(
              title: 'Show results immediately',
              subtitle: 'Students can see results right after submission',
              value: _showResultsImmediately,
              onChanged: _isSaving
                  ? null
                  : (v) {
                      setState(() {
                        _showResultsImmediately = v;
                        _formError = null;
                      });
                      _scheduleAutoSave();
                    },
            ),
            const SizedBox(height: 8),

            // Publish toggle
            _buildSwitchTile(
              title: 'Publish immediately',
              subtitle: 'Students can see this assessment right away',
              value: _isPublished,
              onChanged: _isSaving
                  ? null
                  : (v) {
                      setState(() {
                        _isPublished = v;
                        _formError = null;
                      });
                      _scheduleAutoSave();
                    },
            ),
            const SizedBox(height: 16),

            // Quarter dropdown
            DropdownButtonFormField<int?>(
              value: _quarter,
              decoration: _inputDecoration('Quarter (for grading)'),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                ...List.generate(
                  4,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text('Quarter ${i + 1}'),
                  ),
                ),
              ],
              onChanged: _isSaving
                  ? null
                  : (v) {
                      setState(() {
                        _quarter = v;
                        _formError = null;
                      });
                      _scheduleAutoSave();
                    },
            ),
            const SizedBox(height: 16),

            // Grade component dropdown
            DropdownButtonFormField<String?>(
              value: _component,
              decoration: _inputDecoration('Grade Component'),
              items: const [
                DropdownMenuItem(value: null, child: Text('None')),
                DropdownMenuItem(
                    value: 'ww', child: Text('Written Work')),
                DropdownMenuItem(
                    value: 'pt', child: Text('Performance Task')),
                DropdownMenuItem(
                    value: 'qa', child: Text('Quarterly Assessment')),
              ],
              onChanged: _isSaving
                  ? null
                  : (v) {
                      setState(() {
                        _component = v;
                        _isDepartmentalExam = false;
                        _formError = null;
                      });
                      _scheduleAutoSave();
                    },
            ),

            // Departmental exam toggle (only for quarterly assessment)
            if (_component == 'qa') ...[
              const SizedBox(height: 8),
              _buildSwitchTile(
                title: 'Departmental Exam',
                subtitle: 'Mark as departmental quarterly exam',
                value: _isDepartmentalExam,
                onChanged: _isSaving
                    ? null
                    : (v) {
                        setState(() {
                          _isDepartmentalExam = v;
                          _formError = null;
                        });
                        _scheduleAutoSave();
                      },
              ),
            ],

            // TOS link dropdown
            if (tosState.tosList.isNotEmpty) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                value: _linkedTosId,
                decoration: _inputDecoration('Link to TOS (optional)'),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('None')),
                  ...tosState.tosList.map(
                    (tos) => DropdownMenuItem(
                      value: tos.id,
                      child: Text('${tos.title} (Q${tos.gradingPeriodNumber})'),
                    ),
                  ),
                ],
                onChanged: _isSaving
                    ? null
                    : (v) {
                        setState(() {
                          _linkedTosId = v;
                          _formError = null;
                        });
                        _scheduleAutoSave();
                      },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required DateTime dateTime,
    required VoidCallback onPick,
  }) {
    return InkWell(
      onTap: _isSaving ? null : onPick,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _inputDecoration(label).copyWith(
          suffixIcon: const Icon(Icons.arrow_drop_down_rounded,
              color: Color(0xFF666666)),
        ),
        child: Text(
          _formatDateTime(dateTime),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2B2B2B),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: SwitchListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2B2B2B),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
        ),
        value: value,
        activeThumbColor: const Color(0xFF2B2B2B),
        onChanged: onChanged,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Right panel: Questions
  // ---------------------------------------------------------------------------

  Widget _buildQuestionsPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Text(
                  'Questions (${_questions.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2B2B2B),
                  ),
                ),
              ),
              if (_isQuestionReorderMode)
                TextButton.icon(
                  onPressed: _exitQuestionReorderMode,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Done'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2B2B2B),
                  ),
                )
              else if (_questions.length > 1)
                TextButton.icon(
                  onPressed: _enterQuestionReorderMode,
                  icon: const Icon(Icons.swap_vert_rounded, size: 18),
                  label: const Text('Reorder'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF666666),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Question cards
          if (_questions.isEmpty && !_isAddingQuestion)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              alignment: Alignment.center,
              child: const Text(
                'No questions yet. Add your first question below.',
                style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
              ),
            ),

          ...List.generate(_questions.length, (index) {
            final q = _questions[index];
            return _buildQuestionCard(q, index);
          }),

          // Add question form / button
          if (_isAddingQuestion)
            _buildAddQuestionForm()
          else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSaving || _isQuestionReorderMode
                      ? null
                      : _openAddQuestionForm,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Add Question'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2B2B2B),
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuestionDraft q, int index) {
    final typeLabel = _questionTypeLabel(q.type);
    final typeColor = _questionTypeColor(q.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question number
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2B2B2B),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: typeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${q.points} pt${q.points != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  q.questionText.isEmpty
                      ? '(empty question)'
                      : q.questionText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: q.questionText.isEmpty
                        ? const Color(0xFF999999)
                        : const Color(0xFF2B2B2B),
                  ),
                ),
              ],
            ),
          ),
          if (_isQuestionReorderMode)
            IconButton(
              icon: const Icon(Icons.swap_vert_rounded, size: 20),
              onPressed: () => _showQuestionMoveDialog(index),
              tooltip: 'Move',
              color: const Color(0xFF666666),
            )
          else
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: () {
                setState(() => _questions.removeAt(index));
                _scheduleAutoSave();
              },
              tooltip: 'Remove',
              color: const Color(0xFFE57373),
            ),
        ],
      ),
    );
  }

  String _questionTypeLabel(String type) {
    return switch (type) {
      'multiple_choice' => 'Multiple Choice',
      'identification' => 'Identification',
      'enumeration' => 'Enumeration',
      'essay' => 'Essay',
      _ => type,
    };
  }

  Color _questionTypeColor(String type) {
    return switch (type) {
      'multiple_choice' => const Color(0xFF1976D2),
      'identification' => const Color(0xFF388E3C),
      'enumeration' => const Color(0xFFF57C00),
      'essay' => const Color(0xFF7B1FA2),
      _ => const Color(0xFF666666),
    };
  }

  // ---------------------------------------------------------------------------
  // Add question inline form
  // ---------------------------------------------------------------------------

  Widget _buildAddQuestionForm() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2B2B2B), width: 1.5),
      ),
      child: Form(
        key: _addQuestionFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Question',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2B2B2B),
              ),
            ),
            const SizedBox(height: 16),

            // Question type
            DropdownButtonFormField<String>(
              value: _newQuestionType,
              decoration: _inputDecoration('Question Type'),
              items: const [
                DropdownMenuItem(
                    value: 'multiple_choice',
                    child: Text('Multiple Choice')),
                DropdownMenuItem(
                    value: 'identification',
                    child: Text('Identification')),
                DropdownMenuItem(
                    value: 'enumeration', child: Text('Enumeration')),
                DropdownMenuItem(value: 'essay', child: Text('Essay')),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _newQuestionType = v;
                    _newChoices = [ChoiceDraft(), ChoiceDraft()];
                    _newAcceptableAnswers = [''];
                    _newEnumerationItems = [EnumerationItemDraft()];
                  });
                }
              },
            ),
            const SizedBox(height: 12),

            // Question text
            TextFormField(
              controller: _newQuestionTextController,
              decoration: _inputDecoration('Question Text'),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Question text is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Points
            TextFormField(
              controller: _newQuestionPointsController,
              decoration: _inputDecoration('Points'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Points required';
                }
                final parsed = int.tryParse(value.trim());
                if (parsed == null || parsed <= 0) {
                  return 'Enter a valid point value';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Multi-select toggle for MCQ
            if (_newQuestionType == 'multiple_choice') ...[
              _buildSwitchTile(
                title: 'Multi-select',
                subtitle: 'Allow selecting multiple correct answers',
                value: _newQuestionMultiSelect,
                onChanged: (v) =>
                    setState(() => _newQuestionMultiSelect = v),
              ),
              const SizedBox(height: 12),
            ],

            // Type-specific fields
            if (_newQuestionType == 'multiple_choice')
              _buildChoicesEditor(),
            if (_newQuestionType == 'identification')
              _buildIdentificationEditor(),
            if (_newQuestionType == 'enumeration')
              _buildEnumerationEditor(),
            if (_newQuestionType == 'essay')
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Essay questions are graded manually. No additional fields needed.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
                ),
              ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _cancelAddQuestion,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF666666),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _confirmAddQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B2B2B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Choices editor (multiple choice)
  // ---------------------------------------------------------------------------

  Widget _buildChoicesEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choices',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2B2B2B),
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(_newChoices.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Checkbox(
                  value: _newChoices[i].isCorrect,
                  activeColor: const Color(0xFF2B2B2B),
                  onChanged: (v) {
                    setState(() => _newChoices[i].isCorrect = v ?? false);
                  },
                ),
                Expanded(
                  child: TextFormField(
                    initialValue: _newChoices[i].text,
                    decoration: _inputDecoration('Choice ${i + 1}'),
                    onChanged: (v) => _newChoices[i].text = v,
                  ),
                ),
                if (_newChoices.length > 2)
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: Color(0xFFE57373)),
                    onPressed: () {
                      setState(() => _newChoices.removeAt(i));
                    },
                  ),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              setState(() => _newChoices.add(ChoiceDraft()));
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Choice'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF666666),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Identification editor
  // ---------------------------------------------------------------------------

  Widget _buildIdentificationEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acceptable Answers',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2B2B2B),
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(_newAcceptableAnswers.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _newAcceptableAnswers[i],
                    decoration: _inputDecoration('Answer ${i + 1}'),
                    onChanged: (v) => _newAcceptableAnswers[i] = v,
                  ),
                ),
                if (_newAcceptableAnswers.length > 1)
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: Color(0xFFE57373)),
                    onPressed: () {
                      setState(() => _newAcceptableAnswers.removeAt(i));
                    },
                  ),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              setState(() => _newAcceptableAnswers.add(''));
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Answer'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF666666),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Enumeration editor
  // ---------------------------------------------------------------------------

  Widget _buildEnumerationEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enumeration Items',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2B2B2B),
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(_newEnumerationItems.length, (itemIndex) {
          final item = _newEnumerationItems[itemIndex];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
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
                        color: Color(0xFF2B2B2B),
                      ),
                    ),
                    const Spacer(),
                    if (_newEnumerationItems.length > 1)
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: 16, color: Color(0xFFE57373)),
                        onPressed: () {
                          setState(
                              () => _newEnumerationItems.removeAt(itemIndex));
                        },
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
                            initialValue: item.answers[ansIndex],
                            decoration: _inputDecoration(
                                'Acceptable answer ${ansIndex + 1}'),
                            onChanged: (v) =>
                                item.answers[ansIndex] = v,
                          ),
                        ),
                        if (item.answers.length > 1)
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 16, color: Color(0xFFE57373)),
                            onPressed: () {
                              setState(
                                  () => item.answers.removeAt(ansIndex));
                            },
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.only(left: 4),
                          ),
                      ],
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: () {
                    setState(() => item.answers.add(''));
                  },
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add Answer',
                      style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF666666),
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
            onPressed: () {
              setState(
                  () => _newEnumerationItems.add(EnumerationItemDraft()));
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Item'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF666666),
            ),
          ),
        ),
      ],
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
    if (newPos != null && newPos >= 1 && newPos <= widget.questionCount) {
      final targetIndex = newPos - 1;
      widget.onMove(widget.currentIndex, targetIndex);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      title: 'Move Question',
      subtitle: 'Question ${widget.currentIndex + 1} of ${widget.questionCount}',
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
