import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/desktop/teacher/grade/class_grading_setup_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/grade/widgets/grade_spreadsheet.dart';
import 'package:likha/presentation/providers/class_provider.dart';
import 'package:likha/presentation/providers/grading_provider.dart';

/// Grades section widget for TeacherClassDetailDesktop
/// Displays grading setup and grade spreadsheet functionality
class GradesSection extends ConsumerStatefulWidget {
  final String classId;

  const GradesSection({
    super.key,
    required this.classId,
  });

  @override
  ConsumerState<GradesSection> createState() => _GradesSectionState();
}

class _GradesSectionState extends ConsumerState<GradesSection> {
  int _selectedQuarter = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gradingConfigProvider.notifier).loadConfig(widget.classId);
      _loadGradeData();
    });
  }

  void _loadGradeData() {
    final itemsNotifier = ref.read(gradeItemsProvider.notifier);
    itemsNotifier.setQuarter(_selectedQuarter);
    itemsNotifier.loadItems(widget.classId).then((_) {
      // Backfill grade items from assessments/assignments
      itemsNotifier.backfillFromActivities(widget.classId, _selectedQuarter).then((_) {
        // After backfill completes, reload items to get newly created ones
        itemsNotifier.loadItems(widget.classId).then((_) {
          final itemsState = ref.read(gradeItemsProvider);
          // Load scores for all items (including newly created ones)
          if (itemsState.items.isNotEmpty) {
            final itemIds = itemsState.items.map((i) => i.id).toList();
            ref.read(gradeScoresProvider.notifier).loadScoresForItems(itemIds);
          }
        });
      });
      // Load quarterly grades summary
      ref.read(quarterlyGradesProvider.notifier).loadSummary(widget.classId, _selectedQuarter);
    });
  }

  void _onQuarterChanged(int quarter) {
    setState(() => _selectedQuarter = quarter);
    _loadGradeData();
  }

  void _handleScoreChanged(
    String studentId,
    String itemId,
    dynamic existingScore,
    double newScore,
  ) {
    ref.read(gradeScoresProvider.notifier).saveScores(itemId, [
      {
        'student_id': studentId,
        'score': newScore,
        if (existingScore != null) 'id': existingScore.id,
      }
    ]);
  }

  void _handleQgChanged(String studentId, int? newQg) {
    if (newQg == null) return;
    ref.read(quarterlyGradesProvider.notifier).updatePeriodGrade(
      classId: widget.classId,
      studentId: studentId,
      quarter: _selectedQuarter,
      transmutedGrade: newQg,
    );
  }

  @override
  Widget build(BuildContext context) {
    final configState = ref.watch(gradingConfigProvider);
    final itemsState = ref.watch(gradeItemsProvider);
    final scoresState = ref.watch(gradeScoresProvider);
    final gradesState = ref.watch(quarterlyGradesProvider);
    final classState = ref.watch(classProvider);
    final students = classState.currentClassDetail?.students ?? [];
    final config = configState.configs.isNotEmpty ? configState.configs.first : null;

    return DesktopPageScaffold(
      title: 'Grades',
      subtitle: 'Quarter $_selectedQuarter',
      actions: [
        // Quarter selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.backgroundTertiary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: DropdownButton<int>(
            value: _selectedQuarter,
            underline: const SizedBox(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundDark,
            ),
            items: List.generate(4, (index) => index + 1).map((quarter) {
              return DropdownMenuItem(
                value: quarter,
                child: Text('Q$quarter'),
              );
            }).toList(),
            onChanged: (quarter) {
              if (quarter != null) _onQuarterChanged(quarter);
            },
          ),
        ),
        const SizedBox(width: 12),
        // Setup button
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClassGradingSetupDesktop(classId: widget.classId),
            ),
          ).then((_) {
            ref.read(gradingConfigProvider.notifier).loadConfig(widget.classId);
            ref.read(gradeItemsProvider.notifier).loadItems(widget.classId);
          }),
          icon: const Icon(Icons.settings_rounded, size: 16),
          label: const Text('Setup'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.foregroundPrimary,
            side: const BorderSide(color: AppColors.foregroundPrimary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
      body: configState.isLoading || itemsState.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.foregroundPrimary,
                strokeWidth: 2.5,
              ),
            )
          : !configState.isConfigured
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.grading_outlined,
                        size: 48,
                        color: AppColors.borderLight,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No grading setup found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.foregroundTertiary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Set up your grading system to start recording grades',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.foregroundTertiary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClassGradingSetupDesktop(classId: widget.classId),
                          ),
                        ),
                        icon: const Icon(Icons.settings_rounded, size: 18),
                        label: const Text('Setup Grading'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.foregroundPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                )
              : gradesState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.foregroundPrimary,
                        strokeWidth: 2.5,
                      ),
                    )
                  : students.isEmpty
                      ? const Center(
                          child: Text(
                            'No students in this class',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.foregroundTertiary,
                            ),
                          ),
                        )
                      : GradeSpreadsheet(
                          students: students,
                          allItems: itemsState.items,
                          scoresByItem: scoresState.scoresByItem,
                          config: config,
                          summary: gradesState.summary,
                          onScoreChanged: _handleScoreChanged,
                          onQgChanged: _handleQgChanged,
                        ),
    );
  }
}
