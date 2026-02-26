// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conflict_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConflictResolutionRequest _$ConflictResolutionRequestFromJson(
  Map<String, dynamic> json,
) => ConflictResolutionRequest(
  conflictId: json['conflict_id'] as String,
  resolution: json['resolution'] as String,
);

Map<String, dynamic> _$ConflictResolutionRequestToJson(
  ConflictResolutionRequest instance,
) => <String, dynamic>{
  'conflict_id': instance.conflictId,
  'resolution': instance.resolution,
};

ConflictResolutionResponse _$ConflictResolutionResponseFromJson(
  Map<String, dynamic> json,
) => ConflictResolutionResponse(
  conflictId: json['conflict_id'] as String,
  winningData: json['winning_data'] as Map<String, dynamic>,
  success: json['success'] as bool,
  error: json['error'] as String?,
);

Map<String, dynamic> _$ConflictResolutionResponseToJson(
  ConflictResolutionResponse instance,
) => <String, dynamic>{
  'conflict_id': instance.conflictId,
  'winning_data': instance.winningData,
  'success': instance.success,
  'error': instance.error,
};
