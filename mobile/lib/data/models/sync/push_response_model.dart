import 'package:json_annotation/json_annotation.dart';

part 'push_response_model.g.dart';

/// Result of processing a single operation
@JsonSerializable()
class OperationResultModel {
  /// Matches the operation ID sent by client
  final String id;

  @JsonKey(name: 'entity_type')
  final String entityType;

  final String operation;

  /// Whether the operation succeeded
  final bool success;

  /// Server-generated ID (for create operations)
  @JsonKey(name: 'server_id')
  final String? serverId;

  /// Error message if operation failed
  final String? error;

  /// Server timestamp after operation
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  /// Additional metadata from server (e.g., nested ID mappings for questions)
  final Map<String, dynamic>? metadata;

  OperationResultModel({
    required this.id,
    required this.entityType,
    required this.operation,
    required this.success,
    this.serverId,
    this.error,
    this.updatedAt,
    this.metadata,
  });

  factory OperationResultModel.fromJson(Map<String, dynamic> json) =>
      _$OperationResultModelFromJson(json);

  Map<String, dynamic> toJson() => _$OperationResultModelToJson(this);
}

/// Response from /sync/push endpoint
@JsonSerializable()
class PushResponseModel {
  /// Results for each operation (one result per input operation)
  final List<OperationResultModel> results;

  PushResponseModel({
    required this.results,
  });

  factory PushResponseModel.fromJson(Map<String, dynamic> json) =>
      _$PushResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$PushResponseModelToJson(this);
}
