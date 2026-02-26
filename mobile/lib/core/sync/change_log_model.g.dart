// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'change_log_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChangeLogEntry _$ChangeLogEntryFromJson(Map<String, dynamic> json) =>
    ChangeLogEntry(
      sequence: (json['sequence'] as num).toInt(),
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      operation: json['operation'] as String,
      performedBy: json['performedBy'] as String,
      payload: json['payload'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$ChangeLogEntryToJson(ChangeLogEntry instance) =>
    <String, dynamic>{
      'sequence': instance.sequence,
      'entityType': instance.entityType,
      'entityId': instance.entityId,
      'operation': instance.operation,
      'performedBy': instance.performedBy,
      'payload': instance.payload,
      'createdAt': instance.createdAt,
    };

ChangesResponse _$ChangesResponseFromJson(Map<String, dynamic> json) =>
    ChangesResponse(
      changes: (json['changes'] as List<dynamic>)
          .map((e) => ChangeLogEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      latestSequence: (json['latestSequence'] as num).toInt(),
      hasMore: json['hasMore'] as bool,
      serverTime: json['serverTime'] as String,
    );

Map<String, dynamic> _$ChangesResponseToJson(ChangesResponse instance) =>
    <String, dynamic>{
      'changes': instance.changes,
      'latestSequence': instance.latestSequence,
      'hasMore': instance.hasMore,
      'serverTime': instance.serverTime,
    };
