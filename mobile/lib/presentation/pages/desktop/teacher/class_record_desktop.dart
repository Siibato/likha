import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/desktop/teacher/class_grading_setup_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/grade_item_scores_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/grade_summary_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/widgets/grade_spreadsheet.dart';
import 'package:likha/presentation/providers/class_provider.dart';
import 'package:likha/presentation/providers/grading_provider.dart';
import 'package:likha/presentation/widgets/styled_dialog.dart';

class ClassRecordDesktop extends ConsumerStatefulWidget {
  final String classId;

  const ClassRecordDesktop({super.key, required this.classId});

  @override
  ConsumerState<ClassRecordDesktop> createState() => _ClassRecordDesktopState();
}

class _ClassRecordDesktopState extends ConsumerState<ClassRecordDesktop>
    with TickerProviderStateMixin {
  int _selectedQuarter = 1;
  late TabController _tabController;
  bool _initialCheckDone = false;

  static const List<String> _componentLabels = [
    'Written Works',
    'Performance Tasks',
    'Quarterly Assessment',
  ];

  static const List<String> _componentKeys = ['ww', 'pt', 'qa'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(classProvider.notifier).loadClassDetail(widget.classId);
      await ref.read(gradingConfigProvider.notifier).loadConfig(widget.classId);

      final configState = ref.read(gradingConfigProvider);
      if (!configState.isConfigured) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ClassGradingSetupDesktop(classId: widget.classId),
            ),
          ).then((_) => _loadData());
        }
      } else {
        _loadData();
      }

      setState(() => _initialCheckDone = true);
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _loadItems();
  }

  void _loadData() {
    _loadItems();
  }

  void _loadItems() {
    final component = _componentKeys[_tabController.index];
    ref.read(gradeItemsProvider.notifier).setQuarter(_selectedQuarter);
    ref.read(gradeItemsProvider.notifier).setComponent(component);
    ref.read(gradeItemsProvider.notifier).loadItems(widget.classId);
  }

  void _onQuarterChanged(int quarter) {
    setState(() => _selectedQuarter = quarter);
    _loadItems();
  }

  double? _getComponentWeight() {
    final configs = ref.read(gradingConfigProvider).configs;
    final config = configs.where((c) => c.quarter == _selectedQuarter).firstOrNull;
    if (config == null) return null;

    switch (_componentKeys[_tabController.index]) {
      case 'ww':
        return config.wwWeight;
      case 'pt':
        return config.ptWeight;
      case 'qa':
        return config.qaWeight;
      default:
        return null;
    }
  }

  void _showAddItemDialog() {
    final component = _componentKeys[_tabController.index];
    final componentLabel = _componentLabels[_tabController.index];

    showDialog(
      context: context,
      builder: (_) => _AddGradeItemDialog(
        classId: widget.classId,
        component: component,
        componentLabel: componentLabel,
        quarter: _selectedQuarter,
      ),
    );
  }

  void _saveInlineScore(
    String studentId,
    String itemId,
    GradeScore? existingScore,
    double newScore,
  ) {
    if (existingScore != null && existingScore.isAutoPopulated) {
      ref.read(gradeScoresProvider.notifier).setOverride(existingScore.id, newScore);
    } else {
      ref.read(gradeScoresProvider.notifier).saveScores(itemId, [
        {'student_id': studentId, 'score': newScore},
      ]);
    }
  }

  void _computeGrades() {
    ref
        .read(quarterlyGradesProvider.notifier)
        .computeGrades(widget.classId, _selectedQuarter);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Computing grades...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openGradeSummary() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GradeSummaryDesktop(
          classId: widget.classId,
          initialQuarter: _selectedQuarter,
        ),
      ),
    );
  }

  void _openGradingSetup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClassGradingSetupDesktop(classId: widget.classId),
      ),
    ).then((_) {
      ref.read(gradingConfigProvider.notifier).loadConfig(widget.classId);
      _loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final classState = ref.watch(classProvider);
    final itemsState = ref.watch(gradeItemsProvider);
    final scoresState = ref.watch(gradeScoresProvider);
    final students = classState.currentClassDetail?.students ?? [];

    // Listen for items load to trigger scores fetch
    ref.listen<GradeItemsState>(gradeItemsProvider, (prev, next) {
      if (prev?.isLoading == true && !next.isLoading && next.items.isNotEmpty) {
        final itemIds = next.items.map((i) => i.id).toList();
        ref.read(gradeScoresProvider.notifier).loadScoresForItems(itemIds);
      }
    });

    final weight = _getComponentWeight();
    final weightLabel = weight != null
        ? '${_componentLabels[_tabController.index]} (${weight.toStringAsFixed(0)}%)'
        : _componentLabels[_tabController.index];

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: 'Class Record',
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.foregroundPrimary,
          ),
          tooltip: 'Back',
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: _openGradeSummary,
            icon: const Icon(Icons.summarize_outlined, size: 18),
            label: const Text('Grade Summary'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.foregroundPrimary,
              side: const BorderSide(color: AppColors.borderLight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _showAddItemDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Item'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.foregroundPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
        body: Column(
          children: [
            // Quarter selector row
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  ...List.generate(4, (index) {
                    final quarter = index + 1;
                    final isSelected = _selectedQuarter == quarter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('Q$quarter'),
                        selected: isSelected,
                        onSelected: (_) => _onQuarterChanged(quarter),
                        selectedColor: AppColors.foregroundPrimary,
                        backgroundColor: AppColors.backgroundPrimary,
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.backgroundPrimary
                              : AppColors.foregroundPrimary,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.foregroundPrimary
                              : AppColors.borderLight,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        showCheckmark: false,
                      ),
                    );
                  }),
                  const Spacer(),
                  IconButton(
                    onPressed: _openGradingSetup,
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: AppColors.foregroundSecondary,
                      size: 20,
                    ),
                    tooltip: 'Grading Setup',
                  ),
                ],
              ),
            ),

            // Tab bar
            Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundPrimary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.foregroundPrimary,
                unselectedLabelColor: AppColors.foregroundTertiary,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                indicatorColor: AppColors.foregroundPrimary,
                indicatorWeight: 2.5,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'WW'),
                  Tab(text: 'PT'),
                  Tab(text: 'QA'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Spreadsheet
            Expanded(
              child: itemsState.isLoading || scoresState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.foregroundPrimary,
                        strokeWidth: 2.5,
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: List.generate(3, (tabIndex) {
                        final componentItems = itemsState.items
                            .where(
                                (i) => i.component == _componentKeys[tabIndex])
                            .toList();

                        return GradeSpreadsheet(
                          students: students,
                          items: componentItems,
                          scoresByItem: scoresState.scoresByItem,
                          weightLabel: weightLabel,
                          onHeaderTap: (item) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GradeItemScoresDesktop(
                                  classId: widget.classId,
                                  gradeItem: item,
                                ),
                              ),
                            ).then((_) => _loadItems());
                          },
                          onScoreChanged: (studentId, itemId, existingScore, score) {
                            _saveInlineScore(studentId, itemId, existingScore, score);
                          },
                        );
                      }),
                    ),
            ),

            // Bottom action bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.backgroundPrimary,
                border: Border(
                  top: BorderSide(color: AppColors.borderLight),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.icon(
                    onPressed: _computeGrades,
                    icon: const Icon(Icons.calculate_outlined, size: 18),
                    label: const Text('Compute Grades'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.foregroundPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog to add a new grade item to a component.
class _AddGradeItemDialog extends ConsumerStatefulWidget {
  final String classId;
  final String component;
  final String componentLabel;
  final int quarter;

  const _AddGradeItemDialog({
    required this.classId,
    required this.component,
    required this.componentLabel,
    required this.quarter,
  });

  @override
  ConsumerState<_AddGradeItemDialog> createState() =>
      _AddGradeItemDialogState();
}

class _AddGradeItemDialogState extends ConsumerState<_AddGradeItemDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _pointsController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _pointsController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  void _handleAddItem() {
    final title = _titleController.text.trim();
    final points = double.tryParse(_pointsController.text.trim());
    if (title.isEmpty || points == null || points <= 0) return;

    ref.read(gradeItemsProvider.notifier).createItem(
      widget.classId,
      {
        'title': title,
        'component': widget.component,
        'quarter': widget.quarter,
        'total_points': points,
      },
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      title: 'Add Grade Item',
      subtitle: 'Component: ${widget.componentLabel}',
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: StyledTextFieldDecoration.styled(
                labelText: 'Title',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pointsController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              decoration: StyledTextFieldDecoration.styled(
                labelText: 'Total Points',
              ),
            ),
          ],
        ),
      ),
      actions: [
        StyledDialogAction(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        StyledDialogAction(
          label: 'Add Item',
          isPrimary: true,
          onPressed: _handleAddItem,
        ),
      ],
    );
  }
}

