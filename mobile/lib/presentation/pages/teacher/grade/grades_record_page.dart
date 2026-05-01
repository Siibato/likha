import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/layouts/mobile/mobile_page_scaffold.dart';
import 'package:likha/core/logging/page_logger.dart';
import 'package:likha/domain/grading/entities/grade_config.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/widgets/mobile/teacher/grade/add_grade_item_dialog.dart';
import 'package:likha/presentation/widgets/mobile/teacher/grade/grade_export_dialog.dart';
import 'package:likha/presentation/widgets/mobile/teacher/grade/quarter_selector.dart';
import 'package:likha/presentation/pages/teacher/class/class_grading_setup_page.dart';
import 'package:likha/presentation/pages/teacher/grade/grade_summary_page.dart';
import 'package:likha/presentation/providers/class_provider.dart';
import 'package:likha/presentation/providers/grading_provider.dart';
import 'package:likha/presentation/widgets/shared/teacher/grade/grade_spreadsheet.dart';
import 'package:likha/presentation/widgets/shared/teacher/grade/grade_spreadsheet_cells.dart';

class ClassRecordPage extends ConsumerStatefulWidget {
  final String classId;

  const ClassRecordPage({super.key, required this.classId});

  @override
  ConsumerState<ClassRecordPage> createState() => _ClassRecordPageState();
}

class _ClassRecordPageState extends ConsumerState<ClassRecordPage> {
  int _selectedQuarter = 1;
  bool _initialCheckDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  // ── Data loading ─────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    ref.read(classProvider.notifier).loadClassDetail(widget.classId);
    await ref.read(gradingConfigProvider.notifier).loadConfig(widget.classId);

    final configState = ref.read(gradingConfigProvider);
    if (!_initialCheckDone && mounted) {
      _initialCheckDone = true;
      if (!configState.isConfigured && !configState.isLoading && configState.error == null) {
        _navigateToSetup();
        return;
      }
    }

    if (configState.isConfigured) {
      _loadItemsAndSummary();
    }
  }

  Future<void> _loadItemsAndSummary() async {
    print('*** CLASS RECORD PAGE: Loading items and summary for class: ${widget.classId}, quarter: $_selectedQuarter');
    PageLogger.instance.log('Loading items and summary for class: ${widget.classId}, quarter: $_selectedQuarter');

    final itemsNotifier = ref.read(gradeItemsProvider.notifier);
    itemsNotifier.setQuarter(_selectedQuarter);
    itemsNotifier.setComponent(''); // load all components

    try {
      print('*** CLASS RECORD PAGE: Loading grade items for class: ${widget.classId}');
      PageLogger.instance.log('Loading grade items for class: ${widget.classId}');
      await itemsNotifier.loadItems(widget.classId);

      print('*** CLASS RECORD PAGE: Starting backfill from activities for quarter: $_selectedQuarter');
      PageLogger.instance.log('Starting backfill from activities for quarter: $_selectedQuarter');
      await itemsNotifier.backfillFromActivities(widget.classId, _selectedQuarter);

      // Reload to pick up items created during backfill
      await itemsNotifier.loadItems(widget.classId);

      final itemsState = ref.read(gradeItemsProvider);
      if (itemsState.items.isNotEmpty) {
        final itemIds = itemsState.items.map((i) => i.id).toList();

        // Load any scores already in the DB so the sheet is not blank while generating
        print('*** CLASS RECORD PAGE: Loading scores for ${itemIds.length} grade items');
        PageLogger.instance.log('Loading scores for ${itemIds.length} grade items');
        await ref.read(gradeScoresProvider.notifier).loadScoresForItems(itemIds);

        // Show skeleton cells during score generation
        ref.read(gradeScoresProvider.notifier).setGenerating(true);
        // Auto-populate scores from assessment/assignment submissions
        print('*** CLASS RECORD PAGE: Generating scores for grade items');
        PageLogger.instance.log('Generating scores for grade items');
        await itemsNotifier.generateScoresForItems(widget.classId);

        // Reload scores to surface newly generated values
        print('*** CLASS RECORD PAGE: Refreshing scores after generation');
        PageLogger.instance.log('Refreshing scores after generation');
        final refreshedIds = ref.read(gradeItemsProvider).items.map((i) => i.id).toList();
        if (refreshedIds.isNotEmpty) {
          await ref.read(gradeScoresProvider.notifier).loadScoresForItems(refreshedIds);
        }
        ref.read(gradeScoresProvider.notifier).setGenerating(false);
      } else {
        print('*** CLASS RECORD PAGE: No grade items found for class: ${widget.classId}, quarter: $_selectedQuarter');
        PageLogger.instance.warn('No grade items found for class: ${widget.classId}, quarter: $_selectedQuarter');
      }
    } catch (e) {
      print('*** CLASS RECORD PAGE: Error loading grade data: $e');
      PageLogger.instance.error('Error loading grade data', e);
    }

    print('*** CLASS RECORD PAGE: Loading quarterly grades summary for class: ${widget.classId}, quarter: $_selectedQuarter');
    PageLogger.instance.log('Loading quarterly grades summary for class: ${widget.classId}, quarter: $_selectedQuarter');
    ref
        .read(quarterlyGradesProvider.notifier)
        .loadSummary(widget.classId, _selectedQuarter);
  }

  void _navigateToSetup() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ClassGradingSetupPage(classId: widget.classId),
      ),
    );
    if (result == true && mounted) {
      _initialCheckDone = false;
      _loadData();
    }
  }

  void _onQuarterChanged(int quarter) {
    PageLogger.instance.log('Quarter changed from $_selectedQuarter to $quarter');
    setState(() => _selectedQuarter = quarter);
    _loadItemsAndSummary();
  }

  // ── Add item ─────────────────────────────────────────────────────────────

  void _showAddGradeItemDialog() {
    showAddGradeItemDialog(
      context: context,
      classId: widget.classId,
      selectedQuarter: _selectedQuarter,
      ref: ref,
    );

    // Reload items and scores after dialog closes
    Future.delayed(Duration.zero, () => _loadItemsAndSummary());
  }

  void _showExportDialog(BuildContext context, {required bool isDownload}) {
    showGradeExportDialog(
      context,
      ref,
      classId: widget.classId,
      quarter: _selectedQuarter,
      isDownload: isDownload,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  GradeConfig? _configForQuarter(List<dynamic> configs) {
    for (final c in configs) {
      if ((c as GradeConfig).gradingPeriodNumber == _selectedQuarter) return c;
    }
    return configs.isNotEmpty ? configs.first as GradeConfig : null;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final classState = ref.watch(classProvider);
    final configState = ref.watch(gradingConfigProvider);
    final itemsState = ref.watch(gradeItemsProvider);
    final scoresState = ref.watch(gradeScoresProvider);
    final gradesState = ref.watch(quarterlyGradesProvider);

    final students = classState.currentClassDetail?.students ?? [];
    final config = _configForQuarter(configState.configs);

    ref.listen<GradeItemsState>(gradeItemsProvider, (prev, next) {
      PageLogger.instance.log('Grade items state changed - loading: ${next.isLoading}, items count: ${next.items.length}');
    });

    final isLoading = configState.isLoading ||
        (configState.isConfigured &&
            itemsState.isLoading &&
            itemsState.items.isEmpty);

    return MobilePageScaffold(
      title: 'Class Record',
      scrollable: false,
      isLoading: isLoading,
      header: const ClassSectionHeader(
        title: 'Class Record',
        showBackButton: true,
      ),
      floatingActionButton: configState.isConfigured
          ? FloatingActionButton(
              backgroundColor: AppColors.accentCharcoal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              onPressed: _showAddGradeItemDialog,
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          // Quarter chips + actions
          QuarterSelector(
              selectedQuarter: _selectedQuarter,
              onQuarterChanged: _onQuarterChanged,
              onComputeGrades: () async {
                final messenger = ScaffoldMessenger.of(context);
                await ref
                    .read(quarterlyGradesProvider.notifier)
                    .computeGrades(widget.classId, _selectedQuarter);
                if (!mounted) return;
                ref
                    .read(quarterlyGradesProvider.notifier)
                    .loadSummary(widget.classId, _selectedQuarter);
                messenger.showSnackBar(
                    const SnackBar(content: Text('Grades computed')));
              },
              onFinalGrades: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GradeSummaryPage(
                    classId: widget.classId,
                    initialQuarter: _selectedQuarter,
                  ),
                ),
              ),
              onGradingSettings: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClassGradingSetupPage(
                    classId: widget.classId,
                  ),
                ),
              ),
              onDownload: () => _showExportDialog(context, isDownload: true),
              onPrint: () => _showExportDialog(context, isDownload: false),
            ),

            // Content
            if (!configState.isConfigured)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.tune_outlined,
                          size: 64, color: AppColors.foregroundLight),
                      SizedBox(height: 16),
                      Text('Grading not configured',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.foregroundTertiary)),
                      SizedBox(height: 8),
                      Text('Set up grading weights to get started',
                          style:
                              TextStyle(fontSize: 13, color: AppColors.foregroundLight)),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: GradeSpreadsheet(
                  students: students,
                  allItems: itemsState.items,
                  scoresByItem: scoresState.scoresByItem,
                  config: config,
                  summary: gradesState.summary,
                  dimensions: const GradeSpreadsheetDimensions.compact(),
                  isLoadingScores: scoresState.isGeneratingScores,
                  onScoreChanged: (studentId, itemId, existing, newScore) async {
                    try {
                      if (existing != null && existing.isAutoPopulated) {
                        await ref
                            .read(gradeScoresProvider.notifier)
                            .setOverride(existing.id, newScore);
                      } else {
                        await ref.read(gradeScoresProvider.notifier).saveScores(
                          itemId,
                          [{'student_id': studentId, 'score': newScore}],
                        );
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Score saved'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to save score: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  onQgChanged: (studentId, grade) {
                    if (grade == null) return;
                    ref.read(quarterlyGradesProvider.notifier).updatePeriodGrade(
                          classId: widget.classId,
                          studentId: studentId,
                          quarter: _selectedQuarter,
                          transmutedGrade: grade,
                        );
                  },
                  onAddColumn: (_) => _showAddGradeItemDialog(),
                ),
              ),
        ],
      ),
    );
  }
}
