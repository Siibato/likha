// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'full_sync_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FullSyncResponseModel _$FullSyncResponseModelFromJson(
  Map<String, dynamic> json,
) => FullSyncResponseModel(
  syncToken: json['sync_token'] as String,
  serverTime: json['server_time'] as String,
  classes: (json['classes'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList(),
  enrollments: (json['enrollments'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList(),
  assessments: (json['assessments'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList(),
  questions: (json['questions'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList(),
  assessmentSubmissions: (json['assessment_submissions'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList(),
  assignments: (json['assignments'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList(),
  assignmentSubmissions: (json['assignment_submissions'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList(),
  learningMaterials: (json['learning_materials'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList(),
);

Map<String, dynamic> _$FullSyncResponseModelToJson(
  FullSyncResponseModel instance,
) => <String, dynamic>{
  'sync_token': instance.syncToken,
  'server_time': instance.serverTime,
  'classes': instance.classes,
  'enrollments': instance.enrollments,
  'assessments': instance.assessments,
  'questions': instance.questions,
  'assessment_submissions': instance.assessmentSubmissions,
  'assignments': instance.assignments,
  'assignment_submissions': instance.assignmentSubmissions,
  'learning_materials': instance.learningMaterials,
};
