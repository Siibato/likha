/// Returns an error message if [value] is null or empty after trimming.
String? requiredFieldValidator(String? value, String fieldName) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName is required';
  }
  return null;
}

/// Returns an error message if [value] is not a positive integer.
String? positiveIntValidator(String? value, String fieldName) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName is required';
  }
  final parsed = int.tryParse(value.trim());
  if (parsed == null || parsed <= 0) {
    return 'Enter a valid $fieldName';
  }
  return null;
}
