import 'package:json_annotation/json_annotation.dart';

part 'conflict_model.g.dart';

/// Request to resolve a conflict
@JsonSerializable()
class ConflictResolutionRequest {
  @JsonKey(name: 'conflict_id')
  final String conflictId;

  /// Resolution strategy: "server_wins", "client_wins", "manual"
  final String resolution;

  ConflictResolutionRequest({
    required this.conflictId,
    required this.resolution,
  });

  factory ConflictResolutionRequest.fromJson(Map<String, dynamic> json) =>
      _$ConflictResolutionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ConflictResolutionRequestToJson(this);
}

/// Response from conflict resolution
@JsonSerializable()
class ConflictResolutionResponse {
  @JsonKey(name: 'conflict_id')
  final String conflictId;

  /// The data that won (depending on resolution strategy)
  @JsonKey(name: 'winning_data')
  final Map<String, dynamic> winningData;

  final bool success;

  final String? error;

  ConflictResolutionResponse({
    required this.conflictId,
    required this.winningData,
    required this.success,
    this.error,
  });

  factory ConflictResolutionResponse.fromJson(Map<String, dynamic> json) =>
      _$ConflictResolutionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ConflictResolutionResponseToJson(this);
}
