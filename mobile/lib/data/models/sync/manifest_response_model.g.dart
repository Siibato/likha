// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manifest_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ManifestEntry _$ManifestEntryFromJson(Map<String, dynamic> json) =>
    ManifestEntry(
      id: json['id'] as String,
      updatedAt: json['updated_at'] as String,
      deleted: json['deleted'] as bool,
    );

Map<String, dynamic> _$ManifestEntryToJson(ManifestEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'updated_at': instance.updatedAt,
      'deleted': instance.deleted,
    };

ManifestResponseModel _$ManifestResponseModelFromJson(
  Map<String, dynamic> json,
) => ManifestResponseModel(
  classes: (json['classes'] as List<dynamic>)
      .map((e) => ManifestEntry.fromJson(e as Map<String, dynamic>))
      .toList(),
  enrollments: (json['enrollments'] as List<dynamic>)
      .map((e) => ManifestEntry.fromJson(e as Map<String, dynamic>))
      .toList(),
  assessments: (json['assessments'] as List<dynamic>)
      .map((e) => ManifestEntry.fromJson(e as Map<String, dynamic>))
      .toList(),
  assessmentQuestions: (json['assessment_questions'] as List<dynamic>)
      .map((e) => ManifestEntry.fromJson(e as Map<String, dynamic>))
      .toList(),
  assessmentSubmissions: (json['assessment_submissions'] as List<dynamic>)
      .map((e) => ManifestEntry.fromJson(e as Map<String, dynamic>))
      .toList(),
  assignments: (json['assignments'] as List<dynamic>)
      .map((e) => ManifestEntry.fromJson(e as Map<String, dynamic>))
      .toList(),
  assignmentSubmissions: (json['assignment_submissions'] as List<dynamic>)
      .map((e) => ManifestEntry.fromJson(e as Map<String, dynamic>))
      .toList(),
  learningMaterials: (json['learning_materials'] as List<dynamic>)
      .map((e) => ManifestEntry.fromJson(e as Map<String, dynamic>))
      .toList(),
  serverTime: json['server_time'] as String?,
);

Map<String, dynamic> _$ManifestResponseModelToJson(
  ManifestResponseModel instance,
) => <String, dynamic>{
  'classes': instance.classes,
  'enrollments': instance.enrollments,
  'assessments': instance.assessments,
  'assessment_questions': instance.assessmentQuestions,
  'assessment_submissions': instance.assessmentSubmissions,
  'assignments': instance.assignments,
  'assignment_submissions': instance.assignmentSubmissions,
  'learning_materials': instance.learningMaterials,
  'server_time': instance.serverTime,
};
