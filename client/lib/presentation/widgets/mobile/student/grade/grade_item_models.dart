/// Parsed grade-item data from the API response for a single assessment item.
class GradeItemDetail {
  final String id;
  final String title;
  final String component;
  final double totalPoints;
  final double? score;
  final double? effectiveScore;

  GradeItemDetail({
    required this.id,
    required this.title,
    required this.component,
    required this.totalPoints,
    this.score,
    this.effectiveScore,
  });
}

/// Parsed component weight configuration from the API response.
class GradingConfig {
  final double wwWeight;
  final double ptWeight;
  final double qaWeight;

  GradingConfig({
    required this.wwWeight,
    required this.ptWeight,
    required this.qaWeight,
  });
}

/// Formats a grade number without a trailing ".0" when the value is a whole number.
String formatGradeNum(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}
