import 'package:flutter/material.dart';
import 'package:likha/domain/assessments/entities/assessment_statistics.dart';

class DistractorTable extends StatelessWidget {
  final List<DistractorAnalysis> distractors;

  const DistractorTable({super.key, required this.distractors});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Text(
              'Distractor Analysis',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
          ),
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE0E0E0)),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text('Choice', style: _headerStyle),
                ),
                SizedBox(
                  width: 44,
                  child: Text('Up', style: _headerStyle, textAlign: TextAlign.center),
                ),
                SizedBox(
                  width: 44,
                  child: Text('Low', style: _headerStyle, textAlign: TextAlign.center),
                ),
                SizedBox(
                  width: 44,
                  child: Text('%', style: _headerStyle, textAlign: TextAlign.center),
                ),
                SizedBox(
                  width: 32,
                  child: Text('', style: _headerStyle),
                ),
              ],
            ),
          ),
          // Rows
          ...distractors.map((d) => _DistractorRow(distractor: d)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Color(0xFF999999),
  );
}

class _DistractorRow extends StatelessWidget {
  final DistractorAnalysis distractor;

  const _DistractorRow({required this.distractor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                if (distractor.isCorrect)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.star_rounded, size: 14, color: Color(0xFFF9A825)),
                  ),
                Expanded(
                  child: Text(
                    distractor.choiceText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: distractor.isCorrect ? FontWeight.w600 : FontWeight.w400,
                      color: const Color(0xFF2B2B2B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '${distractor.upperCount}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF2B2B2B)),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '${distractor.lowerCount}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF2B2B2B)),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '${distractor.totalPercentage.toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 12, color: Color(0xFF2B2B2B)),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 32,
            child: Icon(
              distractor.isEffective
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              size: 16,
              color: distractor.isEffective
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFE57373),
            ),
          ),
        ],
      ),
    );
  }
}
