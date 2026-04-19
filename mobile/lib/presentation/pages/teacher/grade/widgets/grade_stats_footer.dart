import 'package:flutter/material.dart';

class GradeStatsFooter extends StatelessWidget {
  final List<Map<String, dynamic>> summary;

  const GradeStatsFooter({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final grades = summary
        .map((r) => _numOrNull(r['quarterly_grade']))
        .whereType<double>()
        .toList();

    if (grades.isEmpty) {
      return const SizedBox.shrink();
    }

    final transmuted = grades.map((g) => g.round()).toList();
    final avg = transmuted.reduce((a, b) => a + b) / transmuted.length;
    final highest = transmuted.reduce((a, b) => a > b ? a : b);
    final lowest = transmuted.reduce((a, b) => a < b ? a : b);
    final passing = transmuted.where((g) => g >= 75).length;
    final passRate = ((passing / transmuted.length) * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('Average', avg.toStringAsFixed(1)),
          _statItem('Highest', highest.toString()),
          _statItem('Lowest', lowest.toString()),
          _statItem('Pass Rate', '$passRate%'),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B2B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF999999),
          ),
        ),
      ],
    );
  }

  double? _numOrNull(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
