import 'package:flutter/material.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';

class TosCompetencyRow extends StatelessWidget {
  final TosCompetency competency;
  final int totalDays;
  final String timeUnit;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TosCompetencyRow({
    super.key,
    required this.competency,
    required this.totalDays,
    this.timeUnit = 'days',
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final weight = totalDays > 0
        ? (competency.daysTaught / totalDays * 100).toStringAsFixed(1)
        : '0.0';

    return GestureDetector(
      onTap: onEdit,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (competency.competencyCode != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        competency.competencyCode!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                  Text(
                    competency.competencyText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2B2B2B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${competency.daysTaught} $timeUnit taught',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF999999),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$weight%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onDelete != null)
              GestureDetector(
                onTap: onDelete,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.close, size: 18, color: Color(0xFF999999)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
