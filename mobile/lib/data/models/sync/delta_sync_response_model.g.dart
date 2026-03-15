// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delta_sync_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EntityDeltas _$EntityDeltasFromJson(Map<String, dynamic> json) => EntityDeltas(
  updated: (json['updated'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList(),
  deleted: (json['deleted'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$EntityDeltasToJson(EntityDeltas instance) =>
    <String, dynamic>{'updated': instance.updated, 'deleted': instance.deleted};

DeltaPayload _$DeltaPayloadFromJson(Map<String, dynamic> json) => DeltaPayload(
  classes: EntityDeltas.fromJson(json['classes'] as Map<String, dynamic>),
  enrollments: EntityDeltas.fromJson(
    json['enrollments'] as Map<String, dynamic>,
  ),
  assessments: EntityDeltas.fromJson(
    json['assessments'] as Map<String, dynamic>,
  ),
  questions: EntityDeltas.fromJson(json['questions'] as Map<String, dynamic>),
  assessmentSubmissions: EntityDeltas.fromJson(
    json['assessment_submissions'] as Map<String, dynamic>,
  ),
  assignments: EntityDeltas.fromJson(
    json['assignments'] as Map<String, dynamic>,
  ),
  assignmentSubmissions: EntityDeltas.fromJson(
    json['assignment_submissions'] as Map<String, dynamic>,
  ),
  learningMaterials: EntityDeltas.fromJson(
    json['learning_materials'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$DeltaPayloadToJson(DeltaPayload instance) =>
    <String, dynamic>{
      'classes': instance.classes,
      'enrollments': instance.enrollments,
      'assessments': instance.assessments,
      'questions': instance.questions,
      'assessment_submissions': instance.assessmentSubmissions,
      'assignments': instance.assignments,
      'assignment_submissions': instance.assignmentSubmissions,
      'learning_materials': instance.learningMaterials,
    };

DeltaSyncResponseModel _$DeltaSyncResponseModelFromJson(
  Map<String, dynamic> json,
) => DeltaSyncResponseModel(
  syncToken: json['sync_token'] as String?,
  serverTime: json['server_time'] as String?,
  deltas: json['deltas'] == null
      ? null
      : DeltaPayload.fromJson(json['deltas'] as Map<String, dynamic>),
  status: json['status'] as String?,
  message: json['message'] as String?,
);

Map<String, dynamic> _$DeltaSyncResponseModelToJson(
  DeltaSyncResponseModel instance,
) => <String, dynamic>{
  'sync_token': instance.syncToken,
  'server_time': instance.serverTime,
  'deltas': instance.deltas,
  'status': instance.status,
  'message': instance.message,
};
