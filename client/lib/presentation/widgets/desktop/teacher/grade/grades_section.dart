import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/teacher/grade/class_grading_setup_page.dart';
import 'package:likha/presentation/widgets/shared/teacher/grade/grade_spreadsheet.dart';
import 'package:likha/presentation/widgets/shared/teacher/grade/grade_spreadsheet_cells.dart';
import 'package:likha/presentation/widgets/mobile/teacher/grade/add_grade_item_dialog.dart';
import 'package:likha/presentation/pages/mobile/teacher/grade/grade_summary_page.dart';
import 'package:likha/presentation/providers/auth_provider.dart';
import 'package:likha/presentation/providers/class_grades_provider.dart';
import 'package:likha/presentation/providers/class_provider.dart';
import 'package:likha/presentation/providers/grading_provider.dart';
import 'package:likha/presentation/providers/school_settings_provider.dart';
import 'package:likha/services/grade_export_service.dart';

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
  int _selectedQuarter = 1;
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
        gradingPeriodNumber: _selectedQuarter,
      );
    }
  }

  void _reloadGrades() {
    ref.read(classGradesProvider.notifier).loadClassGrades(
      classId: widget.classId,
      gradingPeriodNumber: _selectedQuarter,
      skipBackgroundRefresh: true,
    );
  }

  void _onQuarterChanged(int quarter) {
    setState(() => _selectedQuarter = quarter);
    ref.read(classGradesProvider.notifier).loadClassGrades(
      classId: widget.classId,
      gradingPeriodNumber: quarter,
    );
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
      },
    ]);
    _reloadGrades();
  }

  void _showAddGradeItemDialog() {
    showAddGradeItemDialog(
      context: context,
      classId: widget.classId,
      selectedQuarter: _selectedQuarter,
      ref: ref,
    );
  }

  void _handleAddColumn(String component) {
    // Redirect to mobile-style dialog for consistency
    _showAddGradeItemDialog();
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Export Grades'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choose export format:'),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Excel'),
                subtitle: const Text('Editable spreadsheet (.xlsx)'),
                leading: const Icon(Icons.table_chart),
                onTap: () {
                  Navigator.of(context).pop();
                  _exportToExcel();
                },
              ),
              ListTile(
                title: const Text('PDF'),
                subtitle: const Text('Printable document (.pdf)'),
                leading: const Icon(Icons.picture_as_pdf),
                onTap: () {
                  Navigator.of(context).pop();
                  _exportToPdf();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _exportToExcel() async {
    try {
      final classState = ref.read(classProvider);
      final gradesState = ref.read(classGradesProvider);
      final configState = ref.read(gradingConfigProvider);
      final authState = ref.read(authProvider);
      final schoolState = ref.read(schoolSettingsProvider);
      final grades = gradesState.grades;
      if (grades == null) return;

      final students = classState.currentClassDetail?.students ?? [];
      final config = configState.configs.isNotEmpty ? configState.configs.first : null;
      final detail = classState.currentClassDetail;

      await ref.read(gradeExportServiceProvider).exportToExcel(
        classId: widget.classId,
        className: detail?.title ?? 'Unknown Class',
        quarter: _selectedQuarter,
        students: students,
        gradeItems: grades.items,
        scoresByItem: grades.scoresByItem,
        config: config,
        summary: grades.summary ?? const [],
        schoolSettings: schoolState.settings,
        teacherName: authState.user?.fullName,
        gradeLevel: detail?.gradeLevel,
        section: detail?.title,
        subject: detail?.title,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excel exported successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export Excel: $e')),
        );
      }
    }
  }

  void _exportToPdf() async {
    try {
      final classState = ref.read(classProvider);
      final gradesState = ref.read(classGradesProvider);
      final configState = ref.read(gradingConfigProvider);
      final authState = ref.read(authProvider);
      final schoolState = ref.read(schoolSettingsProvider);
      final grades = gradesState.grades;
      if (grades == null) return;

      final students = classState.currentClassDetail?.students ?? [];
      final config = configState.configs.isNotEmpty ? configState.configs.first : null;
      final detail = classState.currentClassDetail;

      await ref.read(gradeExportServiceProvider).exportToPdf(
        classId: widget.classId,
        quarter: _selectedQuarter,
        className: detail?.title ?? 'Unknown Class',
        students: students,
        gradeItems: grades.items,
        scoresByItem: grades.scoresByItem,
        config: config,
        summary: grades.summary ?? const [],
        schoolSettings: schoolState.settings,
        teacherName: authState.user?.fullName,
        gradeLevel: detail?.gradeLevel,
        section: detail?.title,
        subject: detail?.title,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF exported successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export PDF: $e')),
        );
      }
    }
  }

  void _handleQgChanged(String studentId, int? newQg) {
    if (newQg == null) return;
    ref
        .read(quarterlyGradesProvider.notifier)
        .updatePeriodGrade(
          classId: widget.classId,
          studentId: studentId,
          quarter: _selectedQuarter,
          transmutedGrade: newQg,
        );
    _reloadGrades();
  }

  @override
  Widget build(BuildContext context) {
    final configState = ref.watch(gradingConfigProvider);
    final gradesState = ref.watch(classGradesProvider);
    final classState = ref.watch(classProvider);
    final students = classState.currentClassDetail?.students ?? [];
    final grades = gradesState.grades;
    final isLoading = gradesState.isLoading && grades == null;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: Column(
        children: [
          // Custom header matching mobile design
          _buildCustomHeader(),

          // Quarter selector and actions
          _buildQuarterSelector(),

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

  Widget _buildQuarterSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 4, 6),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(4, (i) {
                  final q = i + 1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('Q$q'),
                      selected: _selectedQuarter == q,
                      selectedColor: AppColors.accentCharcoal,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _selectedQuarter == q
                            ? Colors.white
                            : AppColors.foregroundSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: _selectedQuarter == q
                              ? AppColors.accentCharcoal
                              : AppColors.borderLight,
                        ),
                      ),
                      onSelected: (_) => _onQuarterChanged(q),
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
                  .read(quarterlyGradesProvider.notifier)
                  .computeGrades(widget.classId, _selectedQuarter);
              if (!mounted) return;
              ref
                  .read(quarterlyGradesProvider.notifier)
                  .loadSummary(widget.classId, _selectedQuarter);
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
                  initialQuarter: _selectedQuarter,
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
