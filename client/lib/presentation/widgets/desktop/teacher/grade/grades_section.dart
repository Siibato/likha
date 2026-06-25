import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/term_utils.dart';
import 'package:likha/presentation/pages/desktop/teacher/grade/class_grading_setup_page.dart';
import 'package:likha/presentation/widgets/shared/teacher/grade/grade_spreadsheet.dart';
import 'package:likha/presentation/widgets/shared/teacher/grade/grade_spreadsheet_cells.dart';
import 'package:likha/presentation/widgets/mobile/teacher/grade/add_grade_item_dialog.dart';
import 'package:likha/presentation/pages/mobile/teacher/grade/grade_summary_page.dart';
import 'package:likha/presentation/providers/class_grades_provider.dart';
import 'package:likha/presentation/providers/class_provider.dart';
import 'package:likha/presentation/providers/grading_provider.dart';
import 'package:likha/presentation/providers/document_export_provider.dart';

/// Grades section widget for TeacherClassDetailDesktop
/// Displays grading setup and grade spreadsheet functionality
class GradesSection extends ConsumerStatefulWidget {
  final String classId;
  final bool isActive;

  const GradesSection({
    super.key,
    required this.classId,
    this.isActive = false,
  });

  @override
  ConsumerState<GradesSection> createState() => _GradesSectionState();
}

class _GradesSectionState extends ConsumerState<GradesSection> {
  int _selectedTerm = 1;
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _hasLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(gradingConfigProvider.notifier).loadConfig(widget.classId);
        _loadGradeData();
      });
    }
  }

  @override
  void didUpdateWidget(GradesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classId != widget.classId) {
      _hasLoaded = false;
    }
    if (!oldWidget.isActive && widget.isActive && !_hasLoaded) {
      _hasLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(gradingConfigProvider.notifier).loadConfig(widget.classId);
        _loadGradeData();
      });
    }
  }

  Future<void> _loadGradeData() async {
    await ref.read(gradingConfigProvider.notifier).loadConfig(widget.classId);

    final configState = ref.read(gradingConfigProvider);
    if (configState.isConfigured) {
      ref.read(classGradesProvider.notifier).loadClassGrades(
        classId: widget.classId,
        termNumber: _selectedTerm,
      );
    }
  }

  void _reloadGrades() {
    ref.read(classGradesProvider.notifier).loadClassGrades(
      classId: widget.classId,
      termNumber: _selectedTerm,
      skipBackgroundRefresh: true,
    );
  }

  void _onTermChanged(int term) {
    setState(() => _selectedTerm = term);
    ref.read(classGradesProvider.notifier).loadClassGrades(
      classId: widget.classId,
      termNumber: term,
    );
  }

  Future<void> _handleScoreChanged(
    String studentId,
    String itemId,
    dynamic existingScore,
    double newScore,
  ) async {
    await ref.read(gradeScoresProvider.notifier).saveScores(itemId, [
      {
        'student_id': studentId,
        'score': newScore,
        if (existingScore != null) 'id': existingScore.id,
      },
    ]);
    _reloadGrades();
  }

  void _showAddGradeItemDialog() {
    showAddGradeItemDialog(
      context: context,
      classId: widget.classId,
      selectedTerm: _selectedTerm,
      ref: ref,
      onCreated: _reloadGrades,
    );
  }

  void _handleAddColumn(String component) {
    // Redirect to mobile-style dialog for consistency
    _showAddGradeItemDialog();
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return _DesktopExportDialog(
          classId: widget.classId,
          termNumber: _selectedTerm,
          parentContext: context,
        );
      },
    );
  }

  void _handleQgChanged(String studentId, int? newQg) {
    if (newQg == null) return;
    ref
        .read(termGradesProvider.notifier)
        .updateTermGrade(
          classId: widget.classId,
          studentId: studentId,
          term: _selectedTerm,
          transmutedGrade: newQg,
        );
    _reloadGrades();
  }

  @override
  Widget build(BuildContext context) {
    final configState = ref.watch(gradingConfigProvider);
    final gradesState = ref.watch(classGradesProvider);
    final classDetailState = ref.watch(classDetailProvider);
    final students = classDetailState.currentClassDetail?.students ?? [];
    final grades = gradesState.grades;
    final isLoading = gradesState.isLoading && grades == null;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: Column(
        children: [
          // Custom header matching mobile design
          _buildCustomHeader(),

          // Term selector and actions
          _buildTermSelector(),

          const Divider(height: 1, color: AppColors.borderLight),

          // Content area
          Expanded(
            child: isLoading
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
                              builder: (_) => ClassGradingSetupPage(
                                classId: widget.classId,
                              ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : grades == null
                ? const SizedBox.shrink()
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
                : Stack(
                    children: [
                      GradeSpreadsheet(
                        students: students,
                        allItems: grades.items,
                        scoresByItem: grades.scoresByItem,
                        config: grades.config,
                        summary: grades.summary ?? const [],
                        dimensions: const GradeSpreadsheetDimensions.standard(),
                        isLoadingScores: false,
                        onScoreChanged: _handleScoreChanged,
                        onQgChanged: _handleQgChanged,
                        onAddColumn: _handleAddColumn,
                      ),
                      // Floating action button
                      Positioned(
                        bottom: 24,
                        right: 24,
                        child: FloatingActionButton(
                          backgroundColor: AppColors.accentCharcoal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          onPressed: _showAddGradeItemDialog,
                          child: const Icon(Icons.add),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // Helper methods for mobile-style design
  Widget _buildCustomHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 3)),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 12, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.backgroundTertiary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.foregroundDark,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Class Record',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.accentCharcoal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 4, 6),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(termCountFromType(null), (i) {
                  final q = i + 1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('T$q'),
                      selected: _selectedTerm == q,
                      selectedColor: AppColors.accentCharcoal,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _selectedTerm == q
                            ? Colors.white
                            : AppColors.foregroundSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: _selectedTerm == q
                              ? AppColors.accentCharcoal
                              : AppColors.borderLight,
                        ),
                      ),
                      onSelected: (_) => _onTermChanged(q),
                    ),
                  );
                }),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calculate_outlined, size: 20),
            color: AppColors.foregroundSecondary,
            tooltip: 'Compute Grades',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await ref
                  .read(termGradesProvider.notifier)
                  .computeGrades(widget.classId, _selectedTerm);
              if (!mounted) return;
              ref
                  .read(termGradesProvider.notifier)
                  .loadSummary(widget.classId, _selectedTerm);
              messenger.showSnackBar(
                const SnackBar(content: Text('Grades computed')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.grade_outlined, size: 20),
            color: AppColors.foregroundSecondary,
            tooltip: 'Final Grades',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GradeSummaryPage(
                  classId: widget.classId,
                  initialTerm: _selectedTerm,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            color: AppColors.foregroundSecondary,
            tooltip: 'Grading Settings',
            onPressed: () =>
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ClassGradingSetupPage(classId: widget.classId),
                  ),
                ).then((_) {
                  ref
                      .read(gradingConfigProvider.notifier)
                      .loadConfig(widget.classId);
                  _reloadGrades();
                }),
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined, size: 20),
            color: AppColors.foregroundSecondary,
            tooltip: 'Download Grades',
            onPressed: () => _showExportDialog(context),
          ),
        ],
      ),
    );
  }
}

class _DesktopExportDialog extends ConsumerWidget {
  final String classId;
  final int termNumber;
  final BuildContext parentContext;

  const _DesktopExportDialog({
    required this.classId,
    required this.termNumber,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportState = ref.watch(documentExportProvider);

    ref.listen<DocumentExportState>(documentExportProvider, (previous, next) {
      if (previous?.isExporting == true && !next.isExporting && next.error == null) {
        Navigator.of(context).pop();
        if (parentContext.mounted) {
          ScaffoldMessenger.of(parentContext).showSnackBar(
            const SnackBar(content: Text('Document exported successfully!')),
          );
        }
      }
    });

    return AlertDialog(
      title: const Text('Export Grades'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose export format:'),
          const SizedBox(height: 16),
          if (exportState.isExporting) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.foregroundPrimary,
                      strokeWidth: 2.5,
                    ),
                    SizedBox(height: 12),
                    Text('Preparing document…'),
                  ],
                ),
              ),
            ),
          ] else ...[
            ListTile(
              title: const Text('Excel'),
              subtitle: const Text('Editable spreadsheet (.xlsx)'),
              leading: const Icon(Icons.table_chart),
              onTap: () {
                ref.read(documentExportProvider.notifier).exportClassGrades(
                  classId: classId,
                  termNumber: termNumber,
                  isPdf: false,
                );
              },
            ),
            if (exportState.error != null) ...[
              const SizedBox(height: 8),
              Text(
                exportState.error!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.semanticError,
                ),
              ),
            ],
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: exportState.isExporting
              ? null
              : () => Navigator.of(context).pop(),
          child: Text(exportState.isExporting ? 'Exporting…' : 'Cancel'),
        ),
      ],
    );
  }
}
