/// Returns the number of terms for a given [termType].
/// Defaults to 4 (term) if the type is null or unrecognized.
int periodCountFromType(String? termType) {
  switch (termType) {
    case 'semester':
      return 2;
    case 'trimester':
      return 3;
    case 'term':
    default:
      return 4;
  }
}

/// Returns a term label prefix based on [termType].
/// - 'term'       → 'T'
/// - 'semester'   → 'S'
/// - 'trimester'  → 'T'
/// - default      → 'T' (term)
String periodLabelPrefix(String? termType) {
  switch (termType) {
    case 'term':
      return 'T';
    case 'semester':
      return 'S';
    case 'trimester':
      return 'T';
    default:
      return 'T';
  }
}
