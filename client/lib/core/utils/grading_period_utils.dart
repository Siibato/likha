/// Returns the number of grading periods for a given [gradingPeriodType].
/// Defaults to 4 (quarterly) if the type is null or unrecognized.
int periodCountFromType(String? gradingPeriodType) {
  switch (gradingPeriodType) {
    case 'semester':
      return 2;
    case 'trimester':
      return 3;
    case 'quarter':
    default:
      return 4;
  }
}

/// Returns a period label prefix based on [gradingPeriodType].
/// - 'quarter'    → 'Q'
/// - 'semester'   → 'S'
/// - 'trimester'  → 'T'
/// - default      → 'T' (term)
String periodLabelPrefix(String? gradingPeriodType) {
  switch (gradingPeriodType) {
    case 'quarter':
      return 'Q';
    case 'semester':
      return 'S';
    case 'trimester':
      return 'T';
    default:
      return 'T';
  }
}
