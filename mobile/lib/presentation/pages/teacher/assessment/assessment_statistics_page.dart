import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/domain/assessments/entities/assessment_statistics.dart';
import 'package:likha/presentation/pages/teacher/widgets/class_performance_card.dart';
import 'package:likha/presentation/pages/teacher/assessment/widgets/item_analysis_tab.dart';
import 'package:likha/presentation/pages/teacher/assessment/widgets/question_analysis_card.dart';
import 'package:likha/presentation/pages/teacher/assessment/widgets/score_distribution_card.dart';
import 'package:likha/presentation/pages/teacher/assessment/widgets/statistics_overview_card.dart';
import 'package:likha/presentation/providers/teacher_assessment_provider.dart';

class AssessmentStatisticsPage extends ConsumerStatefulWidget {
  final String assessmentId;

  const AssessmentStatisticsPage({super.key, required this.assessmentId});

  @override
  ConsumerState<AssessmentStatisticsPage> createState() =>
      _AssessmentStatisticsPageState();
}

class _AssessmentStatisticsPageState
    extends ConsumerState<AssessmentStatisticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(teacherAssessmentProvider.notifier)
          .loadStatistics(widget.assessmentId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teacherAssessmentProvider);
    final stats = state.statistics;

    ref.listen<TeacherAssessmentState>(teacherAssessmentProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        ref.read(teacherAssessmentProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2B2B2B)),
        title: const Text(
          'Statistics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B2B),
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: state.isLoading && stats == null
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2B2B2B),
                strokeWidth: 2.5,
              ),
            )
          : stats == null
              ? const Center(
                  child: Text(
                    'No statistics available',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF999999),
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Tab bar
                    Container(
                      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: const Color(0xFF2B2B2B),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicatorPadding: const EdgeInsets.all(3),
                        labelColor: Colors.white,
                        unselectedLabelColor: const Color(0xFF666666),
                        labelStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        dividerHeight: 0,
                        tabs: const [
                          Tab(text: 'Overview'),
                          Tab(text: 'Item Analysis'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tab content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(stats),
                          ItemAnalysisTab(stats: stats),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab(AssessmentStatistics stats) {
    return RefreshIndicator(
      onRefresh: () => ref
          .read(teacherAssessmentProvider.notifier)
          .loadStatistics(widget.assessmentId),
      color: const Color(0xFF2B2B2B),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatisticsOverviewCard(
              title: stats.title,
              totalPoints: stats.totalPoints,
              submissionCount: stats.submissionCount,
            ),
            const SizedBox(height: 16),
            ClassPerformanceCard(
              classStats: stats.classStatistics,
            ),
            const SizedBox(height: 16),
            ScoreDistributionCard(
              distribution: stats.classStatistics.scoreDistribution,
            ),
            const SizedBox(height: 16),
            if (stats.questionStatistics.isNotEmpty) ...[
              const Text(
                'Per-Question Analysis',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF202020),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              ...stats.questionStatistics.asMap().entries.map(
                    (entry) => QuestionAnalysisCard(
                      index: entry.key,
                      stats: entry.value,
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
