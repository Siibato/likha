import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';
import 'package:likha/presentation/providers/class_provider.dart';
import 'package:likha/presentation/providers/grading_provider.dart';

class GradeItemScoresPage extends ConsumerStatefulWidget {
  final String classId;
  final GradeItem gradeItem;

  const GradeItemScoresPage({
    super.key,
    required this.classId,
    required this.gradeItem,
  });

  @override
  ConsumerState<GradeItemScoresPage> createState() =>
      _GradeItemScoresPageState();
}

class _GradeItemScoresPageState extends ConsumerState<GradeItemScoresPage> {
  final Map<String, TextEditingController> _controllers = {};
  final Set<String> _modifiedStudentIds = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    ref.read(classProvider.notifier).loadClassDetail(widget.classId);
    await ref
        .read(gradeScoresProvider.notifier)
        .loadScoresForItems([widget.gradeItem.id]);

    if (mounted) {
      _initControllers();
      setState(() => _isLoading = false);
    }
  }

  void _initControllers() {
    final classState = ref.read(classProvider);
    final scoresState = ref.read(gradeScoresProvider);
    final students = classState.currentClassDetail?.students ?? [];
    final scores = scoresState.scoresByItem[widget.gradeItem.id] ?? [];

    // Build lookup: studentId -> GradeScore
    final Map<String, GradeScore> scoreLookup = {};
    for (final score in scores) {
      scoreLookup[score.studentId] = score;
    }

    for (final participant in students) {
      final studentId = participant.student.id;
      final existingScore = scoreLookup[studentId];
      final effectiveScore = existingScore?.effectiveScore;

      _controllers[studentId] = TextEditingController(
        text: effectiveScore != null ? _formatScore(effectiveScore) : '',
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _formatScore(double score) {
    if (score == score.roundToDouble()) {
      return score.toInt().toString();
    }
    return score.toStringAsFixed(1);
  }

  Future<void> _saveAllChanges() async {
    if (_modifiedStudentIds.isEmpty) return;

    setState(() => _isSaving = true);

    final List<Map<String, dynamic>> scoresToSave = [];
    for (final studentId in _modifiedStudentIds) {
      final text = _controllers[studentId]?.text.trim() ?? '';
      final score = double.tryParse(text);
      if (score != null) {
        scoresToSave.add({
          'student_id': studentId,
          'score': score,
        });
      }
    }

    if (scoresToSave.isNotEmpty) {
      await ref
          .read(gradeScoresProvider.notifier)
          .saveScores(widget.gradeItem.id, scoresToSave);
    }

    if (mounted) {
      setState(() => _isSaving = false);

      final scoresState = ref.read(gradeScoresProvider);
      if (scoresState.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(scoresState.error!),
            backgroundColor: Colors.red.shade700,
          ),
        );
      } else {
        Navigator.pop(context, true);
      }
    }
  }

  Color _componentColor(String component) {
    return switch (component) {
      'ww' => const Color(0xFF2196F3),
      'pt' => const Color(0xFF4CAF50),
      'qa' => const Color(0xFFFF9800),
      _ => const Color(0xFF999999),
    };
  }

  String _componentLabel(String component) {
    return switch (component) {
      'ww' => 'WW',
      'pt' => 'PT',
      'qa' => 'QA',
      _ => component.toUpperCase(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final classState = ref.watch(classProvider);
    final scoresState = ref.watch(gradeScoresProvider);
    final students = classState.currentClassDetail?.students ?? [];
    final scores = scoresState.scoresByItem[widget.gradeItem.id] ?? [];

    // Build lookup: studentId -> GradeScore
    final Map<String, GradeScore> scoreLookup = {};
    for (final score in scores) {
      scoreLookup[score.studentId] = score;
    }

    // Count graded students
    int gradedCount = 0;
    for (final participant in students) {
      final text = _controllers[participant.student.id]?.text.trim() ?? '';
      if (text.isNotEmpty && double.tryParse(text) != null) {
        gradedCount++;
      }
    }

    final progress = students.isEmpty ? 0.0 : gradedCount / students.length;
    final item = widget.gradeItem;
    final chipColor = _componentColor(item.component);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // AppBar header
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFE0E0E0),
                    width: 3,
                  ),
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 32, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Color(0xFF404040),
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2B2B2B),
                                      letterSpacing: -0.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '/ ${item.totalPoints.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF999999),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: chipColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _componentLabel(item.component),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: chipColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Q${item.gradingPeriodNumber}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF999999),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Progress indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$gradedCount/${students.length} students graded',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF999999),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE0E0E0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF2B2B2B),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Student list
            Expanded(
              child: _isLoading || scoresState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2B2B2B),
                        strokeWidth: 2.5,
                      ),
                    )
                  : students.isEmpty
                      ? const Center(
                          child: Text(
                            'No students enrolled',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF999999),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: students.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final participant = students[index];
                            final studentId = participant.student.id;
                            final existingScore = scoreLookup[studentId];

                            // Ensure controller exists
                            _controllers.putIfAbsent(
                              studentId,
                              () => TextEditingController(),
                            );

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE0E0E0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Student name + icons
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            participant.student.fullName,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF2B2B2B),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (existingScore != null &&
                                            existingScore
                                                .isAutoPopulated) ...[
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.link,
                                            size: 16,
                                            color: Color(0xFF999999),
                                          ),
                                        ],
                                        if (existingScore?.overrideScore !=
                                            null) ...[
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.lock_outline,
                                            size: 16,
                                            color: Color(0xFF999999),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Score input
                                  SizedBox(
                                    width: 100,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        SizedBox(
                                          width: 56,
                                          height: 36,
                                          child: TextField(
                                            controller:
                                                _controllers[studentId],
                                            keyboardType:
                                                const TextInputType
                                                    .numberWithOptions(
                                              decimal: true,
                                            ),
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .allow(
                                                RegExp(r'[\d.]'),
                                              ),
                                            ],
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF2B2B2B),
                                            ),
                                            decoration: InputDecoration(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 6,
                                              ),
                                              isDense: true,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFE0E0E0),
                                                ),
                                              ),
                                              enabledBorder:
                                                  OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFE0E0E0),
                                                ),
                                              ),
                                              focusedBorder:
                                                  OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFF2B2B2B),
                                                  width: 1.5,
                                                ),
                                              ),
                                            ),
                                            onChanged: (_) {
                                              setState(() {
                                                _modifiedStudentIds
                                                    .add(studentId);
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '/ ${item.totalPoints.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF999999),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),

            // Bottom bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _modifiedStudentIds.isEmpty || _isSaving
                        ? null
                        : _saveAllChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B2B2B),
                      disabledBackgroundColor: const Color(0xFFCCCCCC),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white70,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _modifiedStudentIds.isEmpty
                                ? 'No Changes'
                                : 'Save All Changes (${_modifiedStudentIds.length})',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
