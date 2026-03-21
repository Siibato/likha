import 'package:flutter/material.dart';

class ScoreDisplayCard extends StatelessWidget {
  final num score;
  final int totalPoints;
  final bool isLoading;
  final DateTime? gradedAt;
  final bool useBaseCardStyle;
  final String Function(DateTime)? formatDateTime;

  const ScoreDisplayCard({
    super.key,
    required this.score,
    required this.totalPoints,
    this.isLoading = false,
    this.gradedAt,
    this.useBaseCardStyle = false,
    this.formatDateTime,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    final percentage = totalPoints > 0 ? (score / totalPoints) * 100 : 0;
    final scoreFontSize = useBaseCardStyle ? 52.0 : 48.0;
    final denominatorFontSize = useBaseCardStyle ? 26.0 : 24.0;
    final percentageFontSize = useBaseCardStyle ? 18.0 : 16.0;
    final cardPadding = useBaseCardStyle ? 28.0 : 18.0;

    final scoreContent = Padding(
      padding: EdgeInsets.all(cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Score display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                score is int ? '$score' : score.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: scoreFontSize,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2B2B2B),
                  letterSpacing: useBaseCardStyle ? -1.5 : 0,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '/ $totalPoints',
                style: TextStyle(
                  fontSize: denominatorFontSize,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2B2B2B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Percentage badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              border: Border.all(color: const Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: percentageFontSize,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2B2B2B),
                letterSpacing: useBaseCardStyle ? -0.3 : 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: totalPoints > 0 ? (score / totalPoints).clamp(0, 1) : 0,
              minHeight: 10,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2B2B2B)),
            ),
          ),
          // Optional timestamp (assignment card style)
          if (gradedAt != null && formatDateTime != null) ...[
            const SizedBox(height: 8),
            Text(
              formatDateTime!(gradedAt!),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF999999),
              ),
            ),
          ],
        ],
      ),
    );

    // Assembly card style: raw nested containers with depth effect
    if (!useBaseCardStyle) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: scoreContent,
        ),
      );
    }

    // Assignment card style: simpler flat container
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: scoreContent,
    );
  }

  Widget _buildLoadingState() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      padding: const EdgeInsets.all(24),
      child: const Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF2B2B2B),
          ),
        ),
      ),
    );
  }
}
