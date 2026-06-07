class ValidationResult {
  final String entityType;
  final bool isOutdated;
  final DateTime serverTimestamp;
  final int serverRecordCount;
  final bool isOnline;
  final String? error;

  const ValidationResult({
    required this.entityType,
    required this.isOutdated,
    required this.serverTimestamp,
    required this.serverRecordCount,
    required this.isOnline,
    this.error,
  });
}
