// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/layouts/mobile/mobile_page_scaffold.dart';
import 'package:likha/presentation/widgets/shared/primitives/class_section_header.dart';
import 'package:likha/presentation/widgets/mobile/teacher/grade/add_grade_item_dialog.dart';
import 'package:likha/presentation/widgets/mobile/teacher/grade/grade_export_dialog.dart';
import 'package:likha/presentation/widgets/mobile/teacher/grade/term_selector.dart';
import 'package:likha/presentation/pages/mobile/teacher/class/class_grading_setup_page.dart';
import 'package:likha/presentation/pages/mobile/teacher/grade/grade_summary_page.dart';
import 'package:likha/presentation/providers/class_grades_provider.dart';
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
  int _selectedTerm = 1;
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
      ref.read(classGradesProvider.notifier).loadClassGrades(
        classId: widget.classId,
        termNumber: _selectedTerm,
      );
    }
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

  void _onTermChanged(int term) {
    setState(() => _selectedTerm = term);
    ref.read(classGradesProvider.notifier).loadClassGrades(
      classId: widget.classId,
      termNumber: term,
    );
  }

  void _reloadGrades() {
    ref.read(classGradesProvider.notifier).loadClassGrades(
      classId: widget.classId,
      termNumber: _selectedTerm,
      skipBackgroundRefresh: true,
    );
  }

  // ── Add item ─────────────────────────────────────────────────────────────

  void _showAddGradeItemDialog() {
    showAddGradeItemDialog(
      context: context,
      classId: widget.classId,
      selectedTerm: _selectedTerm,
      ref: ref,
    );
  }

  void _showExportDialog(BuildContext context) {
    showGradeExportDialog(
      context,
      ref,
      classId: widget.classId,
      termNumber: _selectedTerm,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final classState = ref.watch(classProvider);
    final configState = ref.watch(gradingConfigProvider);
    final gradesState = ref.watch(classGradesProvider);
    final grades = gradesState.grades;

    final students = classState.currentClassDetail?.students ?? [];

    // Only show skeleton when there is no cached data yet.
    final isLoading = gradesState.isLoading && grades == null;

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
          TermSelector(
            selectedTerm: _selectedTerm,
            onTermChanged: _onTermChanged,
            onComputeGrades: () async {
              final messenger = ScaffoldMessenger.of(context);
              await ref
                  .read(termGradesProvider.notifier)
                  .computeGrades(widget.classId, _selectedTerm);
              if (!mounted) return;
              _reloadGrades();
              messenger.showSnackBar(
                  const SnackBar(content: Text('Grades computed')));
            },
            onFinalGrades: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GradeSummaryPage(
                  classId: widget.classId,
                  initialTerm: _selectedTerm,
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
            onDownload: () => _showExportDialog(context),
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
          else if (grades == null)
            const Expanded(child: SizedBox.shrink())
          else
            Expanded(
              child: GradeSpreadsheet(
                students: students,
                allItems: grades.items,
                scoresByItem: grades.scoresByItem,
                config: grades.config,
                summary: grades.summary ?? const [],
                dimensions: const GradeSpreadsheetDimensions.compact(),
                isLoadingScores: false,
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
                    _reloadGrades();
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
                  ref.read(termGradesProvider.notifier).updateTermGrade(
                        classId: widget.classId,
                        studentId: studentId,
                        term: _selectedTerm,
                        transmutedGrade: grade,
                      );
                  _reloadGrades();
                },
                onAddColumn: (_) => _showAddGradeItemDialog(),
              ),
            ),
        ],
      ),
    );
  }
}
