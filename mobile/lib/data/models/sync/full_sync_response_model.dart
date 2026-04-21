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

  @JsonKey(name: 'material_files', defaultValue: <Map<String, dynamic>>[])
  final List<Map<String, dynamic>> materialFiles;

  @JsonKey(name: 'submission_files', defaultValue: <Map<String, dynamic>>[])
  final List<Map<String, dynamic>> submissionFiles;

  @JsonKey(name: 'assessment_statistics', defaultValue: <Map<String, dynamic>>[])
  final List<Map<String, dynamic>> assessmentStatistics;

  @JsonKey(name: 'student_results', defaultValue: <Map<String, dynamic>>[])
  final List<Map<String, dynamic>> studentResults;

  @JsonKey(name: 'grade_configs', defaultValue: <Map<String, dynamic>>[])
  final List<Map<String, dynamic>> gradeConfigs;

  @JsonKey(name: 'grade_items', defaultValue: <Map<String, dynamic>>[])
  final List<Map<String, dynamic>> gradeItems;

  @JsonKey(name: 'grade_scores', defaultValue: <Map<String, dynamic>>[])
  final List<Map<String, dynamic>> gradeScores;

  @JsonKey(name: 'period_grades', defaultValue: <Map<String, dynamic>>[])
  final List<Map<String, dynamic>> periodGrades;

  @JsonKey(name: 'table_of_specifications', defaultValue: <Map<String, dynamic>>[])
  final List<Map<String, dynamic>> tableOfSpecifications;

  @JsonKey(name: 'tos_competencies', defaultValue: <Map<String, dynamic>>[])
  final List<Map<String, dynamic>> tosCompetencies;

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
    this.materialFiles = const [],
    this.submissionFiles = const [],
    this.assessmentStatistics = const [],
    this.studentResults = const [],
    this.gradeConfigs = const [],
    this.gradeItems = const [],
    this.gradeScores = const [],
    this.periodGrades = const [],
    this.tableOfSpecifications = const [],
    this.tosCompetencies = const [],
    this.user,
    this.enrolledStudents,
  });

  factory FullSyncResponseModel.fromJson(Map<String, dynamic> json) =>
      _$FullSyncResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$FullSyncResponseModelToJson(this);
}
