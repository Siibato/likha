import 'package:flutter/material.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';

class TosSummaryRow extends StatelessWidget {
  final List<TosCompetency> competencies;
  final int totalItems;
  final String timeUnit;

  const TosSummaryRow({
    super.key,
    required this.competencies,
    required this.totalItems,
    this.timeUnit = 'hours',
  });

  @override
  Widget build(BuildContext context) {
    final totalDays = competencies.fold<int>(0, (sum, c) => sum + c.timeUnitsTaught);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          const Text(
            'Total',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2B2B2B),
            ),
          ),
          const Spacer(),
          Text(
            '$totalDays $timeUnit',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '$totalItems items',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}
