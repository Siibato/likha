import 'package:json_annotation/json_annotation.dart';

part 'full_sync_response_model.g.dart';

@JsonSerializable()
class FullSyncResponseModel {
  @JsonKey(name: 'sync_token')
  final String syncToken;

  @JsonKey(name: 'server_time')
  final String serverTime;

  final List<Map<String, dynamic>> classes;
  final List<Map<String, dynamic>> enrollments;
  final List<Map<String, dynamic>> assessments;
  final List<Map<String, dynamic>> questions;

  @JsonKey(name: 'assessment_submissions')
  final List<Map<String, dynamic>> assessmentSubmissions;

  final List<Map<String, dynamic>> assignments;

  @JsonKey(name: 'assignment_submissions')
  final List<Map<String, dynamic>> assignmentSubmissions;

  @JsonKey(name: 'learning_materials')
  final List<Map<String, dynamic>> learningMaterials;

  final Map<String, dynamic>? user;

  @JsonKey(name: 'enrolled_students')
  final List<Map<String, dynamic>>? enrolledStudents;

  FullSyncResponseModel({
    required this.syncToken,
    required this.serverTime,
    required this.classes,
    required this.enrollments,
    required this.assessments,
    required this.questions,
    required this.assessmentSubmissions,
    required this.assignments,
    required this.assignmentSubmissions,
    required this.learningMaterials,
    this.user,
    this.enrolledStudents,
  });

  factory FullSyncResponseModel.fromJson(Map<String, dynamic> json) =>
      _$FullSyncResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$FullSyncResponseModelToJson(this);
}
