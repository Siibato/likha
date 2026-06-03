import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/providers/class_provider.dart';
import 'package:likha/presentation/providers/grading_provider.dart';
import 'package:likha/presentation/widgets/shared/feedback/content_state_builder.dart';

class GradeItemScoresDesktop extends ConsumerStatefulWidget {
  final String classId;
  final GradeItem gradeItem;

  const GradeItemScoresDesktop({
    super.key,
    required this.classId,
    required this.gradeItem,
  });

  @override
  ConsumerState<GradeItemScoresDesktop> createState() =>
      _GradeItemScoresDesktopState();
}

class _GradeItemScoresDesktopState
    extends ConsumerState<GradeItemScoresDesktop> {
  final Map<String, TextEditingController> _controllers = {};
  final Set<String> _modifiedStudentIds = {};
  bool _isLoading = true;
  bool _isSaving = false;

  static const _componentColors = {
    'ww': AppColors.accentCharcoal,
    'pt': AppColors.accentAmber,
    'qa': AppColors.accentCharcoal,
  };

  static const _componentLabels = {
    'ww': 'WW',
    'pt': 'PT',
    'qa': 'QA',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    await ref.read(classProvider.notifier).loadClassDetail(widget.classId);
    await ref
        .read(gradeScoresProvider.notifier)
        .loadScoresForItems([widget.gradeItem.id]);

    _initControllers();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _initControllers() {
    final scoresState = ref.read(gradeScoresProvider);
    final scores = scoresState.scoresByItem[widget.gradeItem.id] ?? [];
    final classState = ref.read(classProvider);
    final students = classState.currentClassDetail?.students ?? [];

    for (final participant in students) {
      final studentId = participant.student.id;
      final score = scores
          .where((s) => s.studentId == studentId)
          .map((s) => s.effectiveScore)
          .firstOrNull;

      final controller = TextEditingController(
        text: score != null ? _formatScore(score) : '',
      );
      controller.addListener(() => _onScoreChanged(studentId));
      _controllers[studentId] = controller;
    }
  }

  void _onScoreChanged(String studentId) {
    setState(() => _modifiedStudentIds.add(studentId));
  }

  String _formatScore(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  Future<void> _saveAll() async {
    if (_modifiedStudentIds.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);

    final scoresToSave = <Map<String, dynamic>>[];
    for (final studentId in _modifiedStudentIds) {
      final controller = _controllers[studentId];
      if (controller == null) continue;

      final text = controller.text.trim();
      if (text.isEmpty) continue;

      final value = double.tryParse(text);
      if (value == null) continue;

      scoresToSave.add({
        'student_id': studentId,
        'score': value,
      });
    }

    await ref
        .read(gradeScoresProvider.notifier)
        .saveScores(widget.gradeItem.id, scoresToSave);

    final error = ref.read(gradeScoresProvider).error;

    if (!mounted) return;

    if (error != null) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.semanticError,
        ),
      );
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classState = ref.watch(classProvider);
    final students = classState.currentClassDetail?.students ?? [];
    final scoresState = ref.watch(gradeScoresProvider);
    final scores = scoresState.scoresByItem[widget.gradeItem.id] ?? [];

    final gradedCount = students.where((p) {
      final score = scores
          .where((s) => s.studentId == p.student.id)
          .map((s) => s.effectiveScore)
          .firstOrNull;
      final controller = _controllers[p.student.id];
      final hasInput = controller != null && controller.text.trim().isNotEmpty;
      return score != null || hasInput;
    }).length;

    final componentColor =
        _componentColors[widget.gradeItem.component] ?? AppColors.accentCharcoal;
    final componentLabel =
        _componentLabels[widget.gradeItem.component] ?? widget.gradeItem.component.toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: widget.gradeItem.title,
        maxWidth: 700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          FilledButton(
            onPressed:
                _modifiedStudentIds.isNotEmpty && !_isSaving ? _saveAll : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.foregroundDark,
              disabledBackgroundColor: AppColors.backgroundDisabled,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save All Changes'),
          ),
        ],
        body: ContentStateBuilder(
              isLoading: _isLoading,
              error: null,
              isEmpty: false,
              onRetry: () {},
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.gradeItem.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.foregroundDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: componentColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      componentLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: componentColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Quarter ${widget.gradeItem.gradingPeriodNumber}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.foregroundSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '/ ${_formatScore(widget.gradeItem.totalPoints)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.foregroundTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Progress indicator
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$gradedCount/${students.length} students graded',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.foregroundSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: students.isEmpty
                              ? 0
                              : gradedCount / students.length,
                          backgroundColor: AppColors.borderLight,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.semanticSuccess,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Student list
                  ...students.map((participant) {
                    final studentId = participant.student.id;
                    final controller = _controllers[studentId];

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      margin: const EdgeInsets.only(bottom: 1),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.borderLight,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              participant.student.fullName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.foregroundPrimary,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: controller,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*'),
                                ),
                              ],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.foregroundDark,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppColors.borderLight,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppColors.borderLight,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppColors.borderPrimary,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '/ ${_formatScore(widget.gradeItem.totalPoints)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.foregroundTertiary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
      ),
    );
  }
}
