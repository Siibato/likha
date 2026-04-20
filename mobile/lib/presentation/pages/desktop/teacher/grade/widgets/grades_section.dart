import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Future<void> _handleAddColumn(String component) async {
    const componentLabels = {
      'ww': 'Written Works',
      'pt': 'Performance Tasks',
      'qa': 'Quarterly Assessment',
    };
    final titleCtrl = TextEditingController();
    final pointsCtrl = TextEditingController();
    int selectedQuarter = _selectedQuarter;
    String selectedComponent = component;
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header ──────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.foregroundPrimary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add_chart_outlined,
                              size: 18,
                              color: AppColors.foregroundPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add Grade Column',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.foregroundDark,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Manually add a column not linked to an LMS activity',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.foregroundSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            color: AppColors.foregroundSecondary,
                            tooltip: 'Cancel',
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.borderLight),

                    // ── Form fields ─────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: titleCtrl,
                            autofocus: true,
                            decoration: const InputDecoration(
                              labelText: 'Column Title',
                              hintText: 'e.g. Quiz 1',
                              prefixIcon: Icon(Icons.title_rounded,
                                  color: AppColors.foregroundSecondary, size: 20),
                              border: OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.foregroundPrimary,
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: pointsCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Total Points',
                              hintText: 'e.g. 50',
                              prefixIcon: Icon(Icons.tag_outlined,
                                  color: AppColors.foregroundSecondary, size: 20),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                            ],
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.foregroundPrimary,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              if (double.tryParse(v.trim()) == null) {
                                return 'Enter a valid number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: selectedComponent,
                            decoration: const InputDecoration(
                              labelText: 'Component',
                              prefixIcon: Icon(Icons.category_outlined,
                                  color: AppColors.foregroundSecondary, size: 20),
                              border: OutlineInputBorder(),
                            ),
                            items: componentLabels.entries
                                .map((e) => DropdownMenuItem(
                                      value: e.key,
                                      child: Text(e.value),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setS(() => selectedComponent = v ?? selectedComponent),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            value: selectedQuarter,
                            decoration: const InputDecoration(
                              labelText: 'Quarter',
                              prefixIcon: Icon(Icons.calendar_month_outlined,
                                  color: AppColors.foregroundSecondary, size: 20),
                              border: OutlineInputBorder(),
                            ),
                            items: List.generate(4, (i) => i + 1)
                                .map((q) => DropdownMenuItem(
                                      value: q,
                                      child: Text('Quarter $q'),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setS(() => selectedQuarter = v ?? selectedQuarter),
                          ),
                        ],
                      ),
                    ),

                    // ── Footer ───────────────────────────────────────────────
                    const Divider(height: 1, color: AppColors.borderLight),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.foregroundSecondary,
                              side: const BorderSide(color: AppColors.borderLight),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            ),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: () {
                              if (formKey.currentState?.validate() ?? false) {
                                Navigator.pop(ctx, true);
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.foregroundDark,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add Column'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    await ref.read(gradeItemsProvider.notifier).createItem(
      widget.classId,
      {
        'title': titleCtrl.text.trim(),
        'component': selectedComponent,
        'grading_period_number': selectedQuarter,
        'total_points': double.parse(pointsCtrl.text.trim()),
        'source_type': 'manual',
        'order_index': 0,
      },
    );

    // Reload items then scores to reflect the new column
    await ref.read(gradeItemsProvider.notifier).loadItems(widget.classId);
    final updatedItemsState = ref.read(gradeItemsProvider);
    if (updatedItemsState.items.isNotEmpty) {
      final itemIds = updatedItemsState.items.map((i) => i.id).toList();
      ref.read(gradeScoresProvider.notifier).loadScoresForItems(itemIds);
    }
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
      scrollable: false,
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
                          onAddColumn: _handleAddColumn,
                        ),
    );
  }
}
