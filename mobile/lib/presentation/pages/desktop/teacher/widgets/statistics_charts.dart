import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/assessment_statistics.dart';

class ScoreDistributionChart extends StatelessWidget {
  final List<ScoreBucket> scoreDistribution;

  const ScoreDistributionChart({super.key, required this.scoreDistribution});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Score Distribution',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          if (scoreDistribution.isEmpty)
            const SizedBox(
              height: 200,
              child: Center(child: Text('No data')),
            )
          else
            SizedBox(
              height: 200,
              child: BarChart(_buildBarChartData()),
            ),
        ],
      ),
    );
  }

  BarChartData _buildBarChartData() {
    final labels = ['0-59', '60-69', '70-79', '80-89', '90-100'];
    final counts = List.filled(5, 0);

    for (final bucket in scoreDistribution) {
      final score = bucket.score;
      if (score < 60) {
        counts[0] += bucket.count;
      } else if (score < 70) {
        counts[1] += bucket.count;
      } else if (score < 80) {
        counts[2] += bucket.count;
      } else if (score < 90) {
        counts[3] += bucket.count;
      } else {
        counts[4] += bucket.count;
      }
    }

    final maxCount = counts.isEmpty ? 1 : counts.reduce((a, b) => a > b ? a : b);

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: (maxCount + 1).toDouble(),
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            return BarTooltipItem(
              '${rod.toY.toInt()} students',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= labels.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  labels[index],
                  style: const TextStyle(fontSize: 11),
                ),
              );
            },
            reservedSize: 30,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              if (value != value.roundToDouble()) {
                return const SizedBox.shrink();
              }
              return Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 11),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      barGroups: List.generate(5, (index) {
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: counts[index].toDouble(),
              color: AppColors.foregroundPrimary,
              width: 20,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class ItemDifficultyChart extends StatelessWidget {
  final List<ItemAnalysis> items;

  const ItemDifficultyChart({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Item Difficulty Index',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const SizedBox(
              height: 200,
              child: Center(child: Text('No data')),
            )
          else
            SizedBox(
              height: 200,
              child: BarChart(_buildBarChartData()),
            ),
        ],
      ),
    );
  }

  Color _barColor(double difficultyIndex) {
    if (difficultyIndex < 0.3) return Colors.red;
    if (difficultyIndex > 0.7) return Colors.green;
    return Colors.orange;
  }

  BarChartData _buildBarChartData() {
    final displayItems = items.length > 30 ? items.sublist(0, 30) : items;

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: 1.0,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final item = displayItems[group.x];
            return BarTooltipItem(
              'Q${group.x + 1}: ${item.difficultyIndex.toStringAsFixed(2)}',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= displayItems.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Q${index + 1}',
                  style: const TextStyle(fontSize: 10),
                ),
              );
            },
            reservedSize: 30,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            interval: 0.2,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toStringAsFixed(1),
                style: const TextStyle(fontSize: 11),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      barGroups: List.generate(displayItems.length, (index) {
        final item = displayItems[index];
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: item.difficultyIndex,
              color: _barColor(item.difficultyIndex),
              width: 20,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        );
      }),
    );
  }
}
