import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/desktop/teacher/class_grading_setup_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/grade_item_scores_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/grade_summary_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/widgets/grade_spreadsheet.dart';
import 'package:likha/presentation/providers/class_provider.dart';
import 'package:likha/presentation/providers/grading_provider.dart';

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
    final titleController = TextEditingController();
    final pointsController = TextEditingController();
    final component = _componentKeys[_tabController.index];
    final componentLabel = _componentLabels[_tabController.index];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Add Grade Item',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.foregroundDark,
          ),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Component: $componentLabel',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.foregroundSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    color: AppColors.foregroundSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.borderPrimary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.foregroundPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pointsController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Total Points',
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    color: AppColors.foregroundSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.borderPrimary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.foregroundPrimary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.foregroundSecondary),
            ),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              final points = double.tryParse(pointsController.text.trim());
              if (title.isEmpty || points == null || points <= 0) return;

              ref.read(gradeItemsProvider.notifier).createItem(
                widget.classId,
                {
                  'title': title,
                  'component': component,
                  'quarter': _selectedQuarter,
                  'total_points': points,
                },
              );
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.foregroundPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Add Item'),
          ),
        ],
      ),
    );
  }

  void _showScoreEntryDialog(
    Participant participant,
    GradeItem item,
    GradeScore? existingScore,
  ) {
    final scoreController = TextEditingController(
      text: existingScore?.effectiveScore?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          participant.student.fullName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.foregroundDark,
          ),
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.title} (/${item.totalPoints})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.foregroundSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: scoreController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Score',
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    color: AppColors.foregroundSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.borderPrimary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.foregroundPrimary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.foregroundSecondary),
            ),
          ),
          FilledButton(
            onPressed: () {
              final score = double.tryParse(scoreController.text.trim());
              if (score == null) return;

              ref.read(gradeScoresProvider.notifier).saveScores(
                item.id,
                [
                  {
                    'student_id': participant.student.id,
                    'score': score,
                  },
                ],
              );
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.foregroundPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
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
                          onCellTap: (participant, item, existingScore) {
                            _showScoreEntryDialog(
                                participant, item, existingScore);
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
