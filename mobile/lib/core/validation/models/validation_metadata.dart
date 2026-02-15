class ValidationMetadata {
  final String entityType;
  final DateTime lastModified;
  final int recordCount;
  final String? etag;
  final DateTime validatedAt;

  const ValidationMetadata({
    required this.entityType,
    required this.lastModified,
    required this.recordCount,
    this.etag,
    required this.validatedAt,
  });

  /// Check if this validation is still fresh (< 5 mins old)
  bool isStillFresh() {
    return DateTime.now().difference(validatedAt).inMinutes < 5;
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'entity_type': entityType,
      'last_modified': lastModified.toIso8601String(),
      'record_count': recordCount,
      'etag': etag,
      'validated_at': validatedAt.toIso8601String(),
    };
  }

  /// Create from JSON for retrieval
  factory ValidationMetadata.fromJson(Map<String, dynamic> json) {
    return ValidationMetadata(
      entityType: json['entity_type'] as String,
      lastModified: DateTime.parse(json['last_modified'] as String),
      recordCount: json['record_count'] as int,
      etag: json['etag'] as String?,
      validatedAt: DateTime.parse(json['validated_at'] as String),
    );
  }
}
