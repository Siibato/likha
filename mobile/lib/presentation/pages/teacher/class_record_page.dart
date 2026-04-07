import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/styled_button.dart';
import 'package:likha/presentation/pages/teacher/class_grading_setup_page.dart';
import 'package:likha/presentation/pages/teacher/grade_item_scores_page.dart';
import 'package:likha/presentation/pages/teacher/grade_summary_page.dart';
import 'package:likha/presentation/providers/class_provider.dart';
import 'package:likha/presentation/providers/grading_provider.dart';

class ClassRecordPage extends ConsumerStatefulWidget {
  final String classId;

  const ClassRecordPage({super.key, required this.classId});

  @override
  ConsumerState<ClassRecordPage> createState() => _ClassRecordPageState();
}

class _ClassRecordPageState extends ConsumerState<ClassRecordPage>
    with TickerProviderStateMixin {
  int _selectedQuarter = 1;
  late TabController _tabController;
  bool _initialCheckDone = false;

  static const _componentLabels = [
    'Written Works',
    'Performance Tasks',
    'Quarterly Assessment',
  ];

  static const _componentKeys = ['ww', 'pt', 'qa'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    ref.read(classProvider.notifier).loadClassDetail(widget.classId);
    await ref.read(gradingConfigProvider.notifier).loadConfig(widget.classId);

    final configState = ref.read(gradingConfigProvider);
    if (!_initialCheckDone && mounted) {
      _initialCheckDone = true;
      if (!configState.isConfigured && !configState.isLoading) {
        _navigateToSetup();
        return;
      }
    }

    if (configState.isConfigured) {
      _loadItemsAndScores();
    }
  }

  void _loadItemsAndScores() {
    ref.read(gradeItemsProvider.notifier).setQuarter(_selectedQuarter);
    ref.read(gradeItemsProvider.notifier).loadItems(widget.classId);
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
    setState(() => _selectedQuarter = quarter);
    ref.read(gradeItemsProvider.notifier).setQuarter(quarter);
    ref.read(gradeItemsProvider.notifier).loadItems(widget.classId);
  }

  void _showAddGradeItemDialog() {
    final titleController = TextEditingController();
    final totalPointsController = TextEditingController(text: '100');
    final component = _componentKeys[_tabController.index];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add ${_componentLabels[_tabController.index]} Item',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2B2B2B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Quarter $_selectedQuarter',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF999999),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Quiz 1, Essay, Lab Activity',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(
                    color: Color(0xFF2B2B2B),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: totalPointsController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Total Points',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(
                    color: Color(0xFF2B2B2B),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: StyledButton(
                    text: 'Cancel',
                    isLoading: false,
                    variant: StyledButtonVariant.outlined,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StyledButton(
                    text: 'Add',
                    isLoading: false,
                    onPressed: () {
                      final title = titleController.text.trim();
                      final points =
                          int.tryParse(totalPointsController.text) ?? 100;
                      if (title.isEmpty) return;

                      ref
                          .read(gradeItemsProvider.notifier)
                          .createItem(widget.classId, {
                        'title': title,
                        'component': component,
                        'quarter': _selectedQuarter,
                        'total_points': points,
                        'source_type': 'manual',
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showScoreEntrySheet({
    required Participant participant,
    required GradeItem item,
    required GradeScore? existingScore,
  }) {
    final effectiveScore = existingScore?.effectiveScore;
    final scoreController = TextEditingController(
      text: effectiveScore != null ? _formatScore(effectiveScore) : '',
    );
    bool isOverride = existingScore?.overrideScore != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                participant.student.fullName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2B2B2B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.title}  /  ${item.totalPoints.toStringAsFixed(0)} pts',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF999999),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: scoreController,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Score',
                  suffixText: '/ ${item.totalPoints.toStringAsFixed(0)}',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(
                      color: Color(0xFF2B2B2B),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              if (existingScore != null &&
                  existingScore.isAutoPopulated) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Override auto-populated score',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: isOverride,
                      activeTrackColor: const Color(0xFF2B2B2B),
                      onChanged: (val) =>
                          setSheetState(() => isOverride = val),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: StyledButton(
                      text: 'Cancel',
                      isLoading: false,
                      variant: StyledButtonVariant.outlined,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StyledButton(
                      text: 'Save',
                      isLoading: false,
                      onPressed: () {
                        final score =
                            double.tryParse(scoreController.text.trim());
                        if (score == null) return;

                        if (existingScore != null &&
                            existingScore.isAutoPopulated &&
                            isOverride) {
                          ref
                              .read(gradeScoresProvider.notifier)
                              .setOverride(existingScore.id, score);
                        } else if (existingScore != null &&
                            !isOverride &&
                            existingScore.overrideScore != null) {
                          ref
                              .read(gradeScoresProvider.notifier)
                              .clearOverride(existingScore.id);
                        } else {
                          ref
                              .read(gradeScoresProvider.notifier)
                              .saveScores(item.id, [
                            {
                              'student_id': participant.student.id,
                              'score': score,
                            },
                          ]);
                        }
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classState = ref.watch(classProvider);
    final configState = ref.watch(gradingConfigProvider);
    final itemsState = ref.watch(gradeItemsProvider);
    final scoresState = ref.watch(gradeScoresProvider);

    final detail = classState.currentClassDetail;
    final students = detail?.students ?? [];

    // When items load, fetch scores for those items
    ref.listen<GradeItemsState>(gradeItemsProvider, (prev, next) {
      if (prev?.isLoading == true &&
          !next.isLoading &&
          next.items.isNotEmpty) {
        final itemIds = next.items.map((i) => i.id).toList();
        ref.read(gradeScoresProvider.notifier).loadScoresForItems(itemIds);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            const ClassSectionHeader(
              title: 'Class Record',
              showBackButton: true,
            ),

            // Quarter selector + settings
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
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
                              selectedColor: const Color(0xFF2B2B2B),
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                color: _selectedQuarter == q
                                    ? Colors.white
                                    : const Color(0xFF666666),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: _selectedQuarter == q
                                      ? const Color(0xFF2B2B2B)
                                      : const Color(0xFFE0E0E0),
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
                    icon: const Icon(Icons.settings_outlined),
                    color: const Color(0xFF666666),
                    onPressed: _navigateToSetup,
                    tooltip: 'Grading Settings',
                  ),
                ],
              ),
            ),

            // Component tabs
            if (configState.isConfigured) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF2B2B2B),
                  unselectedLabelColor: const Color(0xFF999999),
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  indicator: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'WW'),
                    Tab(text: 'PT'),
                    Tab(text: 'QA'),
                  ],
                ),
              ),

              // Spreadsheet grid
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: List.generate(3, (tabIndex) {
                    final component = _componentKeys[tabIndex];
                    final items = itemsState.items
                        .where((it) => it.component == component)
                        .toList();
                    final weight = _getComponentWeight(
                      configState.configs,
                      component,
                    );

                    if (configState.isLoading || itemsState.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2B2B2B),
                          strokeWidth: 2.5,
                        ),
                      );
                    }

                    if (items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.note_add_outlined,
                              size: 48,
                              color: Color(0xFFCCCCCC),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No ${_componentLabels[tabIndex]} items yet',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF999999),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tap + to add one',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFCCCCCC),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return _buildSpreadsheet(
                      students: students,
                      items: items,
                      scoresByItem: scoresState.scoresByItem,
                      weightLabel: '${weight.toStringAsFixed(0)}%',
                    );
                  }),
                ),
              ),

              // Bottom action bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: StyledButton(
                        text: 'Compute Grades',
                        isLoading: false,
                        icon: Icons.calculate_outlined,
                        onPressed: () {
                          ref
                              .read(quarterlyGradesProvider.notifier)
                              .computeGrades(widget.classId, _selectedQuarter);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Computing grades...'),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GradeSummaryPage(
                                classId: widget.classId,
                                initialQuarter: _selectedQuarter,
                              ),
                            ),
                          ),
                          child: const Icon(
                            Icons.summarize_outlined,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (!configState.isLoading) ...[
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.tune_outlined,
                        size: 64,
                        color: Color(0xFFCCCCCC),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Grading not configured',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF999999),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Set up grading weights to get started',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFCCCCCC),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF2B2B2B),
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: configState.isConfigured
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF2B2B2B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onPressed: _showAddGradeItemDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  double _getComponentWeight(
    List<dynamic> configs,
    String component,
  ) {
    // Find config for the current quarter
    for (final config in configs) {
      if (config.quarter == _selectedQuarter) {
        return switch (component) {
          'ww' => config.wwWeight as double,
          'pt' => config.ptWeight as double,
          'qa' => config.qaWeight as double,
          _ => 0.0,
        };
      }
    }
    // Fallback to first config if quarter-specific not found
    if (configs.isNotEmpty) {
      final config = configs.first;
      return switch (component) {
        'ww' => config.wwWeight as double,
        'pt' => config.ptWeight as double,
        'qa' => config.qaWeight as double,
        _ => 0.0,
      };
    }
    return 0.0;
  }

  Widget _buildSpreadsheet({
    required List<Participant> students,
    required List<GradeItem> items,
    required Map<String, List<GradeScore>> scoresByItem,
    required String weightLabel,
  }) {
    const nameColumnWidth = 120.0;
    const cellWidth = 72.0;
    const cellHeight = 44.0;

    // Build a lookup: studentId -> { gradeItemId -> GradeScore }
    final Map<String, Map<String, GradeScore>> scoreLookup = {};
    for (final entry in scoresByItem.entries) {
      for (final score in entry.value) {
        scoreLookup
            .putIfAbsent(score.studentId, () => {})
            [score.gradeItemId] = score;
      }
    }

    return Column(
      children: [
        // Header row
        SizedBox(
          height: cellHeight,
          child: Row(
            children: [
              Container(
                width: nameColumnWidth,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Student',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF999999),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...items.map((item) => GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GradeItemScoresPage(
                                    classId: widget.classId,
                                    gradeItem: item,
                                  ),
                                ),
                              );
                              if (result == true && mounted) {
                                _loadItemsAndScores();
                              }
                            },
                            child: Container(
                              width: cellWidth,
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF666666),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  Text(
                                    '/${item.totalPoints.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Color(0xFF999999),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                      Container(
                        width: cellWidth,
                        alignment: Alignment.center,
                        child: Text(
                          weightLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2B2B2B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE0E0E0)),

        // Student rows
        Expanded(
          child: students.isEmpty
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
                  itemCount: students.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  itemBuilder: (context, index) {
                    final participant = students[index];
                    final studentScores =
                        scoreLookup[participant.student.id] ?? {};

                    return SizedBox(
                      height: cellHeight,
                      child: Row(
                        children: [
                          Container(
                            width: nameColumnWidth,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              participant.student.fullName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2B2B2B),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ...items.map((item) {
                                    final gradeScore =
                                        studentScores[item.id];
                                    final displayScore =
                                        gradeScore?.effectiveScore;
                                    return GestureDetector(
                                      onTap: () => _showScoreEntrySheet(
                                        participant: participant,
                                        item: item,
                                        existingScore: gradeScore,
                                      ),
                                      child: Container(
                                        width: cellWidth,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          border: Border(
                                            left: BorderSide(
                                              color: Colors.grey.shade200,
                                              width: 0.5,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          displayScore != null
                                              ? _formatScore(displayScore)
                                              : '--',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: displayScore != null
                                                ? FontWeight.w500
                                                : FontWeight.w400,
                                            color: displayScore != null
                                                ? const Color(0xFF2B2B2B)
                                                : const Color(0xFFCCCCCC),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                  Container(
                                    width: cellWidth,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8F9FA),
                                      border: Border(
                                        left: BorderSide(
                                          color: Colors.grey.shade200,
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      _computePercentage(
                                        studentScores,
                                        items,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _formatScore(double score) {
    if (score == score.roundToDouble()) {
      return score.toInt().toString();
    }
    return score.toStringAsFixed(1);
  }

  String _computePercentage(
    Map<String, GradeScore> studentScores,
    List<GradeItem> items,
  ) {
    if (studentScores.isEmpty || items.isEmpty) return '--';

    double totalScore = 0;
    double totalPossible = 0;

    for (final item in items) {
      final gradeScore = studentScores[item.id];
      final score = gradeScore?.effectiveScore;
      if (score != null) {
        totalScore += score;
        totalPossible += item.totalPoints;
      }
    }

    if (totalPossible == 0) return '--';
    final pct = (totalScore / totalPossible) * 100;
    return '${pct.toStringAsFixed(0)}%';
  }
}
