// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OperationResultModel _$OperationResultModelFromJson(
  Map<String, dynamic> json,
) => OperationResultModel(
  id: json['id'] as String,
  entityType: json['entity_type'] as String,
  operation: json['operation'] as String,
  success: json['success'] as bool,
  serverId: json['server_id'] as String?,
  error: json['error'] as String?,
  updatedAt: json['updated_at'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$OperationResultModelToJson(
  OperationResultModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'entity_type': instance.entityType,
  'operation': instance.operation,
  'success': instance.success,
  'server_id': instance.serverId,
  'error': instance.error,
  'updated_at': instance.updatedAt,
  'metadata': instance.metadata,
};

PushResponseModel _$PushResponseModelFromJson(Map<String, dynamic> json) =>
    PushResponseModel(
      results: (json['results'] as List<dynamic>)
          .map((e) => OperationResultModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PushResponseModelToJson(PushResponseModel instance) =>
    <String, dynamic>{'results': instance.results};
