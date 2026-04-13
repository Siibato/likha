import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/logging/page_logger.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/utils/snackbar_utils.dart';
import 'package:likha/domain/assessments/usecases/add_questions.dart';
import 'package:likha/domain/assessments/usecases/create_assessment.dart';
import 'package:likha/presentation/pages/teacher/widgets/question_draft.dart';
import 'package:likha/presentation/providers/teacher_assessment_provider.dart';
import 'package:likha/presentation/providers/tos_provider.dart';
import 'package:likha/presentation/pages/teacher/widgets/assessment_details_section.dart';
import 'package:likha/presentation/pages/teacher/widgets/assessment_questions_section.dart';
import 'package:likha/presentation/pages/teacher/widgets/reorder_position_dialog.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/utils/formatters.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/form_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateAssessmentPage extends ConsumerStatefulWidget {
  final String classId;

  const CreateAssessmentPage({super.key, required this.classId});

  @override
  ConsumerState<CreateAssessmentPage> createState() =>
      _CreateAssessmentPageState();
}

class _CreateAssessmentPageState extends ConsumerState<CreateAssessmentPage> {
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

  Future<void> _loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftKey = 'assessment_draft_${widget.classId}';
      final draftJson = prefs.getString(draftKey);

      if (draftJson != null && mounted) {
        final draft = jsonDecode(draftJson) as Map<String, dynamic>;
        _titleController.text = draft['title'] as String? ?? '';
        _descriptionController.text = draft['description'] as String? ?? '';
        _timeLimitController.text = draft['timeLimitMinutes'].toString();
        _openAt = DateTime.parse(draft['openAt'] as String? ?? DateTime.now().toIso8601String());
        _closeAt = DateTime.parse(draft['closeAt'] as String? ?? DateTime.now().add(const Duration(days: 7)).toIso8601String());
        _showResultsImmediately = draft['showResultsImmediately'] as bool? ?? false;
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
    } catch (e) {
      // Ignore draft load errors, continue with empty form
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
      await prefs.setString('assessment_draft_${widget.classId}', jsonEncode(draft));
    } catch (e) {
      // Ignore persistence errors for auto-save
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
      await prefs.remove('assessment_draft_${widget.classId}');
    } catch (e) {
      // Ignore clear errors
    }
  }

  Future<void> _discardDraft() async {
    await _clearDraft();
    if (mounted) {
      setState(() => _draftLoaded = false);
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
      _questions.clear();
    }
  }

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
      builder: (ctx) => ReorderPositionDialog(
        resourceType: 'questions',
        totalCount: _questions.length,
        currentPosition: currentIndex,
        onReorder: (fromIndex, toIndex) {
          setState(() {
            final q = _questions.removeAt(fromIndex);
            _questions.insert(toIndex, q);
          });
          _scheduleAutoSave();
        },
      ),
    );
  }

  bool _validateAll() {
    if (!_detailsFormKey.currentState!.validate()) return false;

    final timeLimit = int.tryParse(_timeLimitController.text.trim());
    if (timeLimit == null || timeLimit <= 0) {
      context.showErrorSnackBar('Please enter a valid time limit');
      return false;
    }

    if (_closeAt.isBefore(_openAt)) {
      context.showErrorSnackBar('Close date must be after open date');
      return false;
    }

    // Validate questions
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.questionText.trim().isEmpty) {
        context.showErrorSnackBar('Question ${i + 1} text is empty');
        return false;
      }
      if (q.type == 'multiple_choice' && q.choices.length < 2) {
        context.showErrorSnackBar('Question ${i + 1} needs at least 2 choices');
        return false;
      }
      if (q.type == 'multiple_choice' && !q.choices.any((c) => c.isCorrect)) {
        context.showErrorSnackBar('Question ${i + 1} needs at least one correct choice');
        return false;
      }
      if (q.type == 'identification' && q.acceptableAnswers.isEmpty) {
        context.showErrorSnackBar('Question ${i + 1} needs at least one acceptable answer');
        return false;
      }
      if (q.type == 'enumeration' && q.enumerationItems.isEmpty) {
        context.showErrorSnackBar('Question ${i + 1} needs at least one enumeration item');
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
  }

  Future<void> _handleSave() async {
    if (!_validateAll()) return;

    setState(() => _isSaving = true);

    try {
      PageLogger.instance.log('_handleSave: Starting assessment creation');

      // Build questionsData for use in both paths
      final questionsData = _buildQuestionsData();

      // Step 1: Create assessment
      // When published: pass questions for atomic creation
      // When draft: pass null (questions added in Step 2)
      PageLogger.instance.log('_handleSave: Calling createAssessment provider method');
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
              tosId: _linkedTosId,
            ),
          );

      PageLogger.instance.log('_handleSave: createAssessment returned assessment=${assessment?.id}');

      if (!mounted) return;

      if (assessment == null) {
        PageLogger.instance.log('_handleSave: Assessment is null, showing error');
        final state = ref.read(teacherAssessmentProvider);
        setState(() => _formError = AppErrorMapper.toUserMessage(state.error));
        setState(() => _isSaving = false);
        return;
      }

      final assessmentId = assessment.id;
      PageLogger.instance.log('_handleSave: Assessment created with ID=$assessmentId');

      // Step 2: Add questions only when DRAFT (published used atomic path above)
      PageLogger.instance.log('_handleSave: isPublished=$_isPublished, questions count=${_questions.length}');
      if (!_isPublished && _questions.isNotEmpty) {
        PageLogger.instance.log('_handleSave: Adding ${_questions.length} questions (draft flow)');
        await ref.read(teacherAssessmentProvider.notifier).addQuestions(
          AddQuestionsParams(
            assessmentId: assessmentId,
            questions: questionsData,
          ),
        );

        PageLogger.instance.log('_handleSave: addQuestions completed');

        if (!mounted) return;
        final state = ref.read(teacherAssessmentProvider);
        if (state.error != null) {
          PageLogger.instance.error('_handleSave: Error after addQuestions', Exception(state.error));
          setState(() => _formError = AppErrorMapper.toUserMessage(state.error));
          setState(() => _isSaving = false);
          return;
        }
      }

      // Success
      PageLogger.instance.log('_handleSave: Clearing draft');
      await _clearDraft();
      ref.read(teacherAssessmentProvider.notifier).clearMessages();
      if (mounted) {
        PageLogger.instance.log('_handleSave: Success! Navigating');
        Navigator.pop(context, true);
      }
    } catch (e) {
      PageLogger.instance.error('_handleSave: Exception caught', e);
      if (mounted) {
        setState(() => _formError = 'An error occurred: $e');
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            const ClassSectionHeader(
              title: 'Create Assessment',
              showBackButton: true,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Draft resume banner
                    if (_draftLoaded)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.restore_rounded, size: 16, color: Color(0xFF666666)),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Resuming draft',
                                style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
                              ),
                            ),
                            TextButton(
                              onPressed: _discardDraft,
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFE57373),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                              child: const Text(
                                'Discard',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Details section
                    const Text(
                      'Assessment Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2B2B2B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FormMessage(
                      message: _formError,
                      severity: MessageSeverity.error,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: AssessmentDetailsSection(
                        formKey: _detailsFormKey,
                        titleController: _titleController,
                        descriptionController: _descriptionController,
                        timeLimitController: _timeLimitController,
                        openAt: _openAt,
                        closeAt: _closeAt,
                        showResultsImmediately: _showResultsImmediately,
                        isPublished: _isPublished,
                        isLoading: _isSaving,
                        onOpenAtChanged: (dt) {
                          setState(() {
                            _openAt = dt;
                            _formError = null;
                          });
                        },
                        onCloseAtChanged: (dt) {
                          setState(() {
                            _closeAt = dt;
                            _formError = null;
                          });
                        },
                        onShowResultsChanged: (value) {
                          setState(() {
                            _showResultsImmediately = value;
                            _formError = null;
                          });
                        },
                        onIsPublishedChanged: (value) {
                          setState(() {
                            _isPublished = value;
                            _formError = null;
                          });
                        },
                        selectedQuarter: _quarter,
                        selectedComponent: _component,
                        isDepartmentalExam: _isDepartmentalExam,
                        onQuarterChanged: (v) => setState(() { _quarter = v; _formError = null; }),
                        onComponentChanged: (v) => setState(() { _component = v; _isDepartmentalExam = false; _formError = null; }),
                        onDepartmentalExamChanged: (v) => setState(() { _isDepartmentalExam = v; _formError = null; }),
                        selectedTosId: _linkedTosId,
                        tosList: ref.watch(tosProvider).tosList,
                        onTosChanged: (v) => setState(() { _linkedTosId = v; _formError = null; }),
                        onCreateAssessment: null,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Questions section
                    Text(
                      'Questions (${_questions.length})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2B2B2B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AssessmentQuestionsSection(
                      questions: _questions,
                      isLoading: _isSaving,
                      isReorderMode: _isQuestionReorderMode,
                      onAddQuestion: _isQuestionReorderMode ? null : () => setState(() => _questions.add(QuestionDraft())),
                      onRemoveQuestion: (index) => setState(() => _questions.removeAt(index)),
                      onQuestionsChanged: _scheduleAutoSave,
                      onSaveQuestions: null,
                      onEnterReorderMode: _questions.length > 1 && !_isQuestionReorderMode ? _enterQuestionReorderMode : null,
                      onExitReorderMode: _isQuestionReorderMode ? _exitQuestionReorderMode : null,
                      onReorderQuestion: _isQuestionReorderMode ? _showQuestionMoveDialog : null,
                    ),
                    const SizedBox(height: 32),

                    // Bottom action bar (now inside scroll view)
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: _isSaving ? null : _saveDraftWithFeedback,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2B2B2B),
                            side: const BorderSide(color: Color(0xFFE0E0E0)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            disabledForegroundColor: const Color(0xFFCCCCCC),
                          ),
                          child: const Text(
                            'Save Draft',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving || _isQuestionReorderMode ? null : _handleSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2B2B2B),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFFE0E0E0),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Save Assessment',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
