/// Returns the number of terms for a given [termType].
/// Defaults to 3 (term) if the type is null or unrecognized.
int termCountFromType(String? termType) {
  switch (termType) {
    case 'semester':
      return 2;
    case 'trimester':
      return 3;
    case 'term':
    default:
      return 3;
  }
}

/// Returns a term label prefix based on [termType].
/// - 'term'       → 'T'
/// - 'semester'   → 'S'
/// - 'trimester'  → 'T'
/// - default      → 'T' (term)
String termLabelPrefix(String? termType) {
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
