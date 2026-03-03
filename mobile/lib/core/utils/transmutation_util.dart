import 'package:likha/domain/assignments/entities/assignment.dart';

/// Philippine DepEd Grade Transmutation Utility
/// Converts raw scores (0–100) to report card grades (60–100)
/// Based on DepEd Memorandum No. 42, s. 2020
class TransmutationUtil {
  /// Apply DepEd transmutation formula to raw score
  ///
  /// Raw scores below 60 map to report grades 60–74 (floor to ~74)
  /// Raw scores 60+ map to report grades 75–100 with steeper slope
  ///
  /// Examples:
  /// - 0 raw → 60 report (floor)
  /// - 60 raw → 75 report (minimum passing on report card)
  /// - 70 raw → 81 report
  /// - 80 raw → 87 report
  /// - 90 raw → 93 report
  /// - 100 raw → 100 report (perfect)
  static int transmute(double rawScore) {
    if (rawScore <= 0) return 60;
    if (rawScore >= 100) return 100;

    if (rawScore < 60) {
      // 0–59.99 range: each 4 points = 1 grade point
      return (rawScore / 4).floor() + 60;
    } else {
      // 60–99.99 range: each ~1.6 points = 1 grade point
      return ((rawScore - 60) / 1.6).floor() + 75;
    }
  }

  /// Compute raw score (0–100) from a list of assignments
  ///
  /// Only includes assignments with graded/returned status
  /// Returns average percentage of earned points / total points
  static double computeRawScore(List<Assignment> assignments) {
    final graded = assignments.where(
      (a) => a.submissionStatus == 'graded' || a.submissionStatus == 'returned',
    ).toList();

    if (graded.isEmpty) return 0;

    final totalScore = graded.fold<int>(0, (sum, a) => sum + (a.score ?? 0));
    final totalPoints = graded.fold<int>(0, (sum, a) => sum + a.totalPoints);

    if (totalPoints == 0) return 0;
    return (totalScore / totalPoints) * 100;
  }

  /// Get DepEd descriptor label for a report card grade
  static String getDescriptor(int reportGrade) {
    if (reportGrade >= 90) return 'Outstanding';
    if (reportGrade >= 85) return 'Very Satisfactory';
    if (reportGrade >= 80) return 'Satisfactory';
    if (reportGrade >= 75) return 'Fairly Satisfactory';
    return 'Did Not Meet Expectations';
  }

  /// Get color for descriptor badge based on report grade
  /// Used only for small status badge, not the main grade number
  static int getDescriptorColor(int reportGrade) {
    if (reportGrade >= 90) return 0xFF4CAF50; // green
    if (reportGrade >= 85) return 0xFF2196F3; // blue
    if (reportGrade >= 80) return 0xFF4A90D9; // blue
    if (reportGrade >= 75) return 0xFFFFC107; // amber
    return 0xFFE57373; // red
  }
}
