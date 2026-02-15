import 'package:json_annotation/json_annotation.dart';

part 'change_log_model.g.dart';

@JsonSerializable()
class ChangeLogEntry {
  final int sequence;
  final String entityType;
  final String entityId;
  final String operation;
  final String performedBy;
  final Map<String, dynamic>? payload;
  final String createdAt;

  ChangeLogEntry({
    required this.sequence,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.performedBy,
    this.payload,
    required this.createdAt,
  });

  factory ChangeLogEntry.fromJson(Map<String, dynamic> json) =>
      _$ChangeLogEntryFromJson(json);

  Map<String, dynamic> toJson() => _$ChangeLogEntryToJson(this);
}

@JsonSerializable()
class ChangesResponse {
  final List<ChangeLogEntry> changes;
  final int latestSequence;
  final bool hasMore;
  final String serverTime;

  ChangesResponse({
    required this.changes,
    required this.latestSequence,
    required this.hasMore,
    required this.serverTime,
  });

  factory ChangesResponse.fromJson(Map<String, dynamic> json) =>
      _$ChangesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ChangesResponseToJson(this);
}
